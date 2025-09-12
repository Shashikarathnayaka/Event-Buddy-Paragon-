import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");
  print("Message notification: ${message.notification?.title}");
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static BuildContext? _context;

  // Set context for showing navigation and feedback
  static void setContext(BuildContext context) {
    _context = context;
  }

  // Initialize push notifications
  static Future<void> initialize() async {
    try {
      // Request permission for iOS and Android 13+
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

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get and save the FCM token
      String? token = await _firebaseMessaging.getToken();
      print("FCM Token: $token");
      await _saveTokenToFirestore(token);

      // Set up message handlers
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle notification tap when app is terminated
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        print("New FCM Token: $token");
        _saveTokenToFirestore(token);
      });

      print("Push notifications initialized successfully");
    } catch (e) {
      print("Error initializing push notifications: $e");
    }
  }

  // Initialize local notifications
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

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  // Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Main event channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'event_buddy_channel',
          'Event Buddy Notifications',
          description: 'Notifications for Event Buddy app',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // New events channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'new_events',
          'New Events',
          description: 'Notifications for newly created events',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Event updates channel
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

  // Save FCM token to Firestore
  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Try to save to users collection first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        return;
      }

      // If not found in users, try organizers collection
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
        // If user doesn't exist in either collection, create in users
        await _firestore.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print("Handling foreground message: ${message.messageId}");
    print("Message data: ${message.data}");

    // Show local notification when app is in foreground
    await _showLocalNotification(message);

    // Show in-app feedback
    _showInAppNotification(message);
  }

  // Show local notification
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

  // Show in-app notification
  static void _showInAppNotification(RemoteMessage message) {
    if (_context == null) return;

    final type = message.data['type'];
    String title = message.notification?.title ?? 'New notification';
    String body = message.notification?.body ?? '';

    // Customize message based on type
    switch (type) {
      case 'event_created':
        title = '🎉 New Event Available!';
        body = message.data['eventName'] != null
            ? 'New event: ${message.data['eventName']}'
            : body;
        break;
      case 'event_updated':
        title = '📝 Event Updated';
        break;
      case 'event_deleted':
        title = '❌ Event Cancelled';
        break;
    }

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (body.isNotEmpty)
                    Text(body, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 53, 137, 158),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _handleNotificationNavigation(message.data),
        ),
      ),
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print("Notification tapped with payload: ${response.payload}");

    if (response.payload != null) {
      try {
        Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        print("Error parsing notification payload: $e");
      }
    }
  }

  // Handle message opened app
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print("Message clicked: ${message.messageId}");
    _handleNotificationNavigation(message.data);
  }

  // Handle navigation based on notification data
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (_context == null) return;

    final type = data['type'];
    final eventId = data['eventId'];

    print("Handling navigation for type: $type, eventId: $eventId");

    switch (type) {
      case 'event_created':
      case 'event_updated':
        if (eventId != null) {
          // Navigate to event detail - you'll need to implement this navigation
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
        print("Unknown notification type: $type");
    }
  }

  // Navigate to event detail (placeholder - implement based on your navigation)
  static void _navigateToEventDetail(String eventId) {
    if (_context == null) return;

    print("Navigating to event detail: $eventId");

    // TODO: Implement navigation to your EventDetailScreen
    // Example:
    // Navigator.of(_context!).pushNamed('/event-detail', arguments: eventId);

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text('Opening event details for: $eventId'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Send event created notification (called after event creation)
  static Future<void> sendEventCreatedNotification({
    required String eventId,
    required String eventName,
    required String organizerId,
    String? eventLocation,
    String? eventDate,
  }) async {
    try {
      // Get all user tokens except the organizer
      final tokens = await _getAllUserTokensExcept(organizerId);

      if (tokens.isEmpty) {
        print("No tokens found for notification");
        return;
      }

      // This would typically call your backend API or Cloud Function
      // For now, we'll just log it
      print("Would send notification to ${tokens.length} users:");
      print("Event: $eventName (ID: $eventId)");
      print("Location: $eventLocation");
      print("Date: $eventDate");

      // Show success feedback to organizer
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
      print("Error sending event created notification: $e");
    }
  }

  // Get all user FCM tokens except the specified user
  static Future<List<String>> _getAllUserTokensExcept(
    String exceptUserId,
  ) async {
    List<String> tokens = [];

    try {
      // Get tokens from users collection
      final usersQuery = await _firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      for (var doc in usersQuery.docs) {
        if (doc.id != exceptUserId && doc.data()['fcmToken'] != null) {
          tokens.add(doc.data()['fcmToken']);
        }
      }

      // Get tokens from organizers collection
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
      print("Error getting user tokens: $e");
    }

    return tokens.toSet().toList(); // Remove duplicates
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print("Subscribed to topic: $topic");
    } catch (e) {
      print("Error subscribing to topic $topic: $e");
    }
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print("Unsubscribed from topic: $topic");
    } catch (e) {
      print("Error unsubscribing from topic $topic: $e");
    }
  }

  // Subscribe to common topics
  static Future<void> subscribeToCommonTopics() async {
    await subscribeToTopic('all_events');
    await subscribeToTopic('event_updates');
  }

  // Get FCM token
  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print("Error getting FCM token: $e");
      return null;
    }
  }

  // Show a test notification (for testing purposes)
  static Future<void> showTestNotification() async {
    await _showLocalNotification(
      RemoteMessage(
        notification: const RemoteNotification(
          title: '🎉 Test Notification',
          body: 'This is a test notification from Event Buddy!',
        ),
        data: {'type': 'test', 'message': 'Test notification'},
      ),
    );
  }

  // Handle event creation (called from AddEventScreen)
  static Future<void> handleEventCreated({
    required String eventId,
    required String eventName,
    required String organizerId,
    String? eventLocation,
    String? eventDate,
    String? eventDescription,
  }) async {
    print("Handling event creation notification...");

    try {
      // Send notifications to users
      await sendEventCreatedNotification(
        eventId: eventId,
        eventName: eventName,
        organizerId: organizerId,
        eventLocation: eventLocation,
        eventDate: eventDate,
      );

      // Show preview notification to organizer
      await _showLocalNotification(
        RemoteMessage(
          notification: RemoteNotification(
            title: '🎉 Event Created Successfully!',
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
      print("Error handling event creation: $e");
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
