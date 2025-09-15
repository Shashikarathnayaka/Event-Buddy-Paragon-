import 'dart:developer';
import 'package:event_buddy/firebase_options.dart';
import 'package:event_buddy/wrapper/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'services/push_notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  log("📩 Background message received: ${message.messageId}");
  log("Message data: ${message.data}");
  if (message.notification != null) {
    log(
      "Notification: ${message.notification!.title} - ${message.notification!.body}",
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    PushNotificationService.setContext(context);
    PushNotificationService.initialize();

    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Event Buddy',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const AuthGate(body: Center(child: Text("Firebase Connected "))),
      ),
    );
  }
}
