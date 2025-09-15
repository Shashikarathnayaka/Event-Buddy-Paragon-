import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
  log("Message data: ${message.data}");
  log("Message notification: ${message.notification?.title}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static BuildContext? _context;

  static void setContext(BuildContext context) {
    _context = context;
  }

  static Future<void> initialize() async {
    try {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
            announcement: false,
            carPlay: false,
            criticalAlert: false,
          );

      print('User granted permission: ${settings.authorizationStatus}');

      await _initializeLocalNotifications();

      String? token = await _firebaseMessaging.getToken();
      print("FCM Token: $token");
      await _saveTokenToFirestore(token);

      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _firebaseMessaging.onTokenRefresh.listen((token) {
        log("New FCM Token: $token");
        _saveTokenToFirestore(token);
      });

      log("Push notifications initialized successfully");
    } catch (e) {
      log("Error initializing push notifications: $e");
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  static Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'event_buddy_channel',
          'Event Buddy Notifications',
          description: 'Notifications for Event Buddy app',
          importance: Importance.high,
          playSound: true,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'new_events',
          'New Events',
          description: 'Notifications for newly created events',
          importance: Importance.high,
          playSound: true,
        ),
      );

      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'event_updates',
          'Event Updates',
          description: 'Notifications for event updates and changes',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        return;
      }

      final orgDoc = await _firestore
          .collection('organizers')
          .doc(userId)
          .get();
      if (orgDoc.exists) {
        await _firestore.collection('organizers').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      log('Error saving FCM token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    log("Handling foreground message: ${message.messageId}");
    log("Message data: ${message.data}");

    await _showLocalNotification(message);

    _showInAppNotification(message);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'event_buddy_channel',
          'Event Buddy Notifications',
          channelDescription: 'Notifications for Event Buddy app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color.fromARGB(255, 53, 137, 158),
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Event Buddy',
      message.notification?.body ?? 'You have a new notification',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  static void _showInAppNotification(RemoteMessage message) {
    if (_context == null) return;

    final type = message.data['type'];
    String title = message.notification?.title ?? 'New notification';
    String body = message.notification?.body ?? '';

    switch (type) {
      case 'event_created':
        title = ' New Event Available!';
        body = message.data['eventName'] != null
            ? 'New event: ${message.data['eventName']}'
            : body;
        break;
      case 'event_updated':
        title = ' Event Updated';
        break;
      case 'event_deleted':
        title = ' Event Cancelled';
        break;
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    log("Notification tapped with payload: ${response.payload}");

    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        log("Error parsing notification payload: $e");
      }
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print("Message clicked: ${message.messageId}");
    _handleNotificationNavigation(message.data);
  }

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (_context == null) return;

    final type = data['type'];
    final eventId = data['eventId'];

    print("Handling navigation for type: $type, eventId: $eventId");

    switch (type) {
      case 'event_created':
      case 'event_updated':
        if (eventId != null) {
          _navigateToEventDetail(eventId);
        }
        break;
      case 'event_deleted':
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text(
              'Event "${data['eventName'] ?? 'Event'}" has been cancelled',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      default:
        log("Unknown notification type: $type");
    }
  }

  static void _navigateToEventDetail(String eventId) {
    if (_context == null) return;

    log("Navigating to event detail: $eventId");

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text('Opening event details for: $eventId'),
        backgroundColor: Colors.green,
      ),
    );
  }

  static Future<void> sendEventCreatedNotification({
    required String eventId,
    required String eventName,
    required String organizerId,
    String? eventLocation,
    String? eventDate,
  }) async {
    try {
      final tokens = await _getAllUserTokensExcept(organizerId);

      if (tokens.isEmpty) {
        print("No tokens found for notification");
        return;
      }

      print("Would send notification to ${tokens.length} users:");
      print("Event: $eventName (ID: $eventId)");
      print("Location: $eventLocation");
      print("Date: $eventDate");

      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text(
              'Event created! ${tokens.length} users will be notified.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      log("Error sending event created notification: $e");
    }
  }

  static Future<List<String>> _getAllUserTokensExcept(
    String exceptUserId,
  ) async {
    List<String> tokens = [];

    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      for (var doc in usersQuery.docs) {
        if (doc.id != exceptUserId && doc.data()['fcmToken'] != null) {
          tokens.add(doc.data()['fcmToken']);
        }
      }

      final organizersQuery = await _firestore
          .collection('organizers')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      for (var doc in organizersQuery.docs) {
        if (doc.id != exceptUserId && doc.data()['fcmToken'] != null) {
          tokens.add(doc.data()['fcmToken']);
        }
      }
    } catch (e) {
      log("Error getting user tokens: $e");
    }

    return tokens.toSet().toList();
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log("Subscribed to topic: $topic");
    } catch (e) {
      log("Error subscribing to topic $topic: $e");
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log("Unsubscribed from topic: $topic");
    } catch (e) {
      log("Error unsubscribing from topic $topic: $e");
    }
  }

  static Future<void> subscribeToCommonTopics() async {
    await subscribeToTopic('all_events');
    await subscribeToTopic('event_updates');
  }

  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      log("Error getting FCM token: $e");
      return null;
    }
  }

  static Future<void> showTestNotification() async {
    await _showLocalNotification(
      RemoteMessage(
        notification: const RemoteNotification(
          title: ' Test Notification',
          body: 'This is a test notification from Event Buddy!',
        ),
        data: {'type': 'test', 'message': 'Test notification'},
      ),
    );
  }

  static Future<void> handleEventCreated({
    required String eventId,
    required String eventName,
    required String organizerId,
    String? eventLocation,
    String? eventDate,
    String? eventDescription,
  }) async {
    log("Handling event creation notification...");

    try {
      await sendEventCreatedNotification(
        eventId: eventId,
        eventName: eventName,
        organizerId: organizerId,
        eventLocation: eventLocation,
        eventDate: eventDate,
      );

      await _showLocalNotification(
        RemoteMessage(
          notification: RemoteNotification(
            title: ' Event Created Successfully!',
            body:
                'Your event "$eventName" is now live and users are being notified!',
          ),
          data: {
            'type': 'event_created',
            'eventId': eventId,
            'eventName': eventName,
            'preview': 'true',
          },
        ),
      );
    } catch (e) {
      log("Error handling event creation: $e");
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(
            content: Text('Event created, but notification sending failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  static void subscribeToEventBuddyTopics() {}
}
