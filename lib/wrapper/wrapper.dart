import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/login_screen.dart';
import 'package:event_buddy/screens/navigation_screen.dart';
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
      return NavigationScreen(
        userName: firstName,
        isOrganizer: role == "Organizer" ? true : false,
      );
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
          log("ERROR");

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

            return NavigationScreen(userName: '');
          },
        );
      },
    );
  }
}
