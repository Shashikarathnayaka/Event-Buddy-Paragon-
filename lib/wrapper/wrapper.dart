import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/login_screen.dart';
import 'package:event_buddy/screens/user_home_screen.dart';
import 'package:event_buddy/screens/organizer_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required Center body});

  Future<Widget> _getHomeScreen(User user) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      String role = doc['role'] ?? '';
      String firstName = doc['firstName'] ?? '';

      if (role == 'User') {
        return UserHomeScreen(userName: firstName);
      } else if (role == 'Organizer') {
        return OrganizerHomeScreen(userName: firstName);
      }
    }

    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          print("ERROR");

          return const LoginScreen();
        }

        return FutureBuilder<Widget>(
          future: _getHomeScreen(snapshot.data!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const LoginScreen();
            }

            return OrganizerHomeScreen(userName: '');
          },
        );
      },
    );
  }
}
