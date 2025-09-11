// import 'package:event_buddy/services/push_notification_service';
// import 'package:event_buddy/wrapper/wrapper.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:toastification/toastification.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase
//   await Firebase.initializeApp();

//   // Initialize Push Notifications
//   await PushNotificationService.initialize();

//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ToastificationWrapper(
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Event Buddy',
//         theme: ThemeData(primarySwatch: Colors.blue),
//         home: const AuthGate(body: Center(child: Text("Firebase Connected "))),
//       ),
//     );
//   }
// }

import 'package:event_buddy/wrapper/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
