// import 'dart:developer';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:event_buddy/screens/login_screen.dart';
// import 'package:event_buddy/screens/navigation_screen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key, required Center body});

//   Future<Widget> _getHomeScreen(User user) async {
//     DocumentSnapshot doc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(user.uid)
//         .get();

//     if (doc.exists) {
//       String role = doc['role'] ?? '';
//       String firstName = doc['firstName'] ?? '';
//       return NavigationScreen(
//         userName: firstName,
//         isOrganizer: role == "Organizer" ? true : false,
//       );
//     }

//     return const LoginScreen();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data == null) {
//           log("ERROR");

//           return const LoginScreen();
//         }

//         return FutureBuilder<Widget>(
//           future: _getHomeScreen(snapshot.data!),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (snapshot.hasError) {
//               return const LoginScreen();
//             }

//             return NavigationScreen(userName: '');
//           },
//         );
//       },
//     );
//   }
// }




// lib/wrapper/wrapper.dart
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> _getUserData(User user) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        String role = doc['role'] ?? '';
        String firstName = doc['firstName'] ?? '';
        return {'firstName': firstName, 'isOrganizer': role == "Organizer"};
      }
    } catch (e) {
      log("Error fetching user data: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          log("User not authenticated");

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/login');
            }
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is logged in - fetch user data and navigate
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserData(snapshot.data!),
          builder: (context, userSnapshot) {
            // Loading user data
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Error or no data
            if (userSnapshot.hasError || !userSnapshot.hasData) {
              log("Error fetching user data or no data found");

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/login');
                }
              });

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Successfully got user data
            final userData = userSnapshot.data!;
            final isOrganizer = userData['isOrganizer'] as bool;

            // Navigate to appropriate home screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                if (isOrganizer) {
                  context.go(
                    '/organizer-home',
                    extra: {
                      'isOrganizer': true,
                      'userName': userData['firstName'],
                    },
                  );
                } else {
                  context.go(
                    '/home',
                    extra: {
                      'isOrganizer': false,
                      'userName': userData['firstName'],
                    },
                  );
                }
              }
            });

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }
}
