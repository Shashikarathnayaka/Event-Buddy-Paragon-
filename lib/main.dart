// import 'package:event_buddy/services/push_notification_service.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:event_buddy/services/auth_service.dart';
// import 'package:event_buddy/screens/add_event_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// // Background message handler
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   print("Handling a background message: ${message.messageId}");
//   print("Title: ${message.notification?.title}");
//   print("Body: ${message.notification?.body}");
//   print("Data: ${message.data}");
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   try {
//     await Firebase.initializeApp();
//     print('Firebase initialized successfully');
//   } catch (e) {
//     print('Error initializing Firebase: $e');
//   }

//   // Set background message handler
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Event Buddy',
//       theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
//       home: AuthWrapper(),
//       routes: {
//         '/add_event': (context) => AddEventScreen(organizer: 'organizer_id'),
//         '/event_details': (context) {
//           final eventId = ModalRoute.of(context)?.settings.arguments as String?;
//           return EventDetailsScreen(eventId: eventId ?? '');
//         },
//         '/home': (context) => MyHomePage(),
//         // Add more routes as needed
//       },
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// // Auth wrapper to check if user is logged in
// class AuthWrapper extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(
//                 color: Color.fromARGB(255, 53, 137, 158),
//               ),
//             ),
//           );
//         }

//         if (snapshot.hasData) {
//           return MyHomePage();
//         } else {
//           return LoginScreen(); // Create this screen or redirect to your login
//         }
//       },
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final AuthService _authService = AuthService();

//   @override
//   void initState() {
//     super.initState();
//     _initializeNotifications();
//   }

//   Future<void> _initializeNotifications() async {
//     try {
//       await NotificationService.initialize(context);
//       print('Notifications initialized');

//       // Update FCM token for current user
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         await _authService.updateUserFCMToken(user.uid);
//         print('FCM token updated for user');
//       }
//     } catch (e) {
//       print('Error initializing notifications: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Event Buddy'),
//         backgroundColor: const Color.fromARGB(255, 53, 137, 158),
//         foregroundColor: Colors.white,
//         elevation: 2,
//         actions: [
//           PopupMenuButton<String>(
//             onSelected: (value) async {
//               switch (value) {
//                 case 'profile':
//                   // Navigate to profile
//                   break;
//                 case 'settings':
//                   // Navigate to settings
//                   break;
//                 case 'logout':
//                   await _authService.signOut();
//                   break;
//               }
//             },
//             itemBuilder: (context) => [
//               PopupMenuItem(value: 'profile', child: Text('Profile')),
//               PopupMenuItem(value: 'settings', child: Text('Settings')),
//               PopupMenuDivider(),
//               PopupMenuItem(value: 'logout', child: Text('Logout')),
//             ],
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.white, Color.fromARGB(255, 240, 248, 255)],
//           ),
//         ),
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.celebration,
//                   size: 80,
//                   color: Color.fromARGB(255, 53, 137, 158),
//                 ),
//                 SizedBox(height: 24),
//                 Text(
//                   'Welcome to Event Buddy!',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Color.fromARGB(255, 53, 137, 158),
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 16),
//                 Text(
//                   'Create amazing events and connect with people',
//                   style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 48),
//                 Container(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       Navigator.pushNamed(context, '/add_event');
//                     },
//                     icon: Icon(Icons.add_circle_outline, size: 24),
//                     label: Text(
//                       'Create New Event',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color.fromARGB(255, 53, 137, 158),
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 4,
//                       shadowColor: Color.fromARGB(
//                         255,
//                         53,
//                         137,
//                         158,
//                       ).withOpacity(0.3),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Container(
//                   width: double.infinity,
//                   height: 56,
//                   child: OutlinedButton.icon(
//                     onPressed: () {
//                       // Navigate to events list
//                       // Navigator.pushNamed(context, '/events_list');
//                     },
//                     icon: Icon(Icons.event_note, size: 24),
//                     label: Text(
//                       'View All Events',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: Color.fromARGB(255, 53, 137, 158),
//                       side: BorderSide(
//                         color: Color.fromARGB(255, 53, 137, 158),
//                         width: 2,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 24),
//                 // Test notification button (remove in production)
//                 TextButton(
//                   onPressed: () {
//                     NotificationService.showLocalNotification(
//                       title: 'Test Notification',
//                       body: 'This is a test notification!',
//                       payload: 'test_event_id',
//                     );
//                   },
//                   child: Text('Test Notification'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Simple login screen placeholder
// class LoginScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Login'),
//         backgroundColor: const Color.fromARGB(255, 53, 137, 158),
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Please Login',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: () {
//                   // Navigate to your actual login screen
//                   // Navigator.pushNamed(context, '/login_form');
//                 },
//                 child: Text('Go to Login'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color.fromARGB(255, 53, 137, 158),
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Placeholder EventDetailsScreen
// class EventDetailsScreen extends StatelessWidget {
//   final String eventId;

//   const EventDetailsScreen({Key? key, required this.eventId}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Event Details'),
//         backgroundColor: const Color.fromARGB(255, 53, 137, 158),
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Event Details',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 16),
//             Text('Event ID: $eventId'),
//             SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Back'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:developer';

import 'package:event_buddy/firebase_options.dart';
import 'package:event_buddy/wrapper/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'services/push_notification_service.dart';

/// 👇 Background message handler MUST be top-level
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

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler BEFORE runApp()
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    /// Initialize Push Notification Service with context
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
