import 'package:event_buddy/screens/navigation_screen.dart';
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

    try {
      User? user;

      if (fromGoogle) {
        user = FirebaseAuth.instance.currentUser;
      } else {
        user = await authService.registerUser(
          email: email!,
          password: password!,
          firstName: firstName ?? "",
          lastName: lastName ?? "",
          dob: dob ?? "",
          role: role,
        );
      }

      if (user == null) throw Exception("User not found");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NavigationScreen(
            userName: firstName ?? user?.displayName ?? "",
            isOrganizer: true,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Choose Your Role"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
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
                child: const Text("User"),
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
                child: const Text("Organizer"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
