import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/navigation_screen.dart';
import 'package:event_buddy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:event_buddy/services/auth_service.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? password;
  final String? dob;
  final bool fromGoogle;

  const RoleSelectionScreen({
    super.key,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.dob,
    this.fromGoogle = false,
  });

  Future<void> saveUserData(BuildContext context, String role) async {
    final authService = AuthService();
    User? user = FirebaseAuth.instance.currentUser;

    debugPrint('fromGoogle: $fromGoogle');
    debugPrint('Current user: ${user?.uid}');
    debugPrint('Email: ${user?.email}');
    debugPrint('Display Name: ${user?.displayName}');
    debugPrint('Provided email: $email');
    debugPrint('Provided password: ${password != null ? 'Present' : 'Null'}');

    if (user == null && !fromGoogle && email != null && password != null) {
      debugPrint('User not found, attempting registration...');

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email!, password: password!);

        user = userCredential.user;

        Navigator.pop(context);

        debugPrint('Registration successful: ${user?.uid}');
      } catch (e) {
        Navigator.pop(context);

        debugPrint('Registration failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (user == null) {
      debugPrint('User still null after registration attempt');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Authentication failed. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final Map<String, dynamic> userData = {
        "firstName": firstName ?? "",
        "lastName": lastName ?? "",
        "email": user.email ?? email ?? "",
        "dob": dob ?? "",
        "role": role,
        "fcmToken": await authService.messaging.getToken().catchError((e) {
          debugPrint('FCM Token error: $e');
          return null;
        }),
        "isActive": true,
        "createdAt": FieldValue.serverTimestamp(),
      };

      debugPrint('Selected Role: $role');
      debugPrint('User ID: ${user.uid}');
      debugPrint('User Data: $userData');

      if (role.toLowerCase() == "organizer") {
        debugPrint('Saving to organizers collection');
        await authService.firestore
            .collection("organizers")
            .doc(user.uid)
            .set(userData);
      } else {
        debugPrint('Saving to users collection');
        await authService.firestore
            .collection("users")
            .doc(user.uid)
            .set(userData);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NavigationScreen(
            userName:
                firstName ??
                user?.displayName ??
                user?.email?.split('@')[0] ??
                "User",
            isOrganizer: role.toLowerCase() == "organizer",
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully registered as ${role.toLowerCase()}!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error saving user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving user data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        title: const Text("Choose Your Role"),
        centerTitle: true,
        backgroundColor: AppColors.card,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/role.svg', height: 200),
            const SizedBox(height: 20),
            const Text(
              "Who would you like to join as?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => saveUserData(context, "User"),
                child: const Text(
                  "User",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => saveUserData(context, "Organizer"),
                child: const Text(
                  "Organizer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Users can join events\n Organizers can create and manage events",
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
