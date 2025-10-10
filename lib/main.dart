// import 'dart:developer';
// import 'package:event_buddy/firebase_options.dart';
// import 'package:event_buddy/screens/splash_screen.dart';
// import 'package:event_buddy/wrapper/wrapper.dart';
// import 'package:event_buddy/services/push_notification_service.dart';
// import 'package:event_buddy/theme/app_theme.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:toastification/toastification.dart';

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   log(" Background message received: ${message.messageId}");
//   log("Message data: ${message.data}");

//   if (message.notification != null) {
//     log(
//       " Notification: ${message.notification!.title} - ${message.notification!.body}",
//     );
//   }
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//   runApp(const ProviderScope(child: MyApp()));
// }

// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     PushNotificationService.setContext(context);
//     PushNotificationService.initialize();

//     return ToastificationWrapper(
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Event Buddy',

//         theme: AppTheme.lightTheme,

//         home: const AuthGate(body: Center(child: Text(""))),

//         routes: {
//           '/splash': (context) => const SplashScreen(),
//           '/auth': (context) =>
//               const AuthGate(body: Center(child: Text("  "))),
//         },
//       ),
//     );
//   }
// }

// /// Developed by Paragon Software Group in 2025
// ///  www.paragon-softwaregroup.com


import 'dart:developer';
import 'package:event_buddy/firebase_options.dart';
import 'package:event_buddy/router.dart';
import 'package:event_buddy/services/push_notification_service.dart';
import 'package:event_buddy/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  log("Background message received: ${message.messageId}");
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

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize Push Notifications
    PushNotificationService.setContext(context);
    PushNotificationService.initialize();

    // Get router from provider (with auth state watching)
    final router = ref.watch(goRouterProvider);

    return ToastificationWrapper(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Event Buddy',
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }
}

/// Developed by Paragon Software Group in 2025
/// www.paragon-softwaregroup.com
