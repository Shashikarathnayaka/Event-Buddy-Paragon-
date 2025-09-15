import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<User?> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String dob,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        String? fcmToken = await _messaging.getToken();

        final Map<String, dynamic> userData = {
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "dob": dob,
          "role": role,
          "fcmToken": fcmToken,
          "isActive": true,
          "createdAt": FieldValue.serverTimestamp(),
        };

        if (role.toLowerCase() == "organizer") {
          await _firestore.collection("organizers").doc(user.uid).set(userData);
        } else {
          await _firestore.collection("users").doc(user.uid).set(userData);
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Registration failed");
    }
  }

  Future<Map<String, dynamic>> loginWithEmail(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      String uid = userCredential.user!.uid;

      String? fcmToken = await _messaging.getToken();

      DocumentSnapshot orgDoc = await _firestore
          .collection('organizers')
          .doc(uid)
          .get();
      if (orgDoc.exists) {
        await _firestore.collection('organizers').doc(uid).update({
          'fcmToken': fcmToken,
          'lastActive': FieldValue.serverTimestamp(),
        });

        return {
          "role": orgDoc['role'] ?? '',
          "firstName": orgDoc['firstName'] ?? '',
        };
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': fcmToken,
          'lastActive': FieldValue.serverTimestamp(),
        });

        return {
          "role": userDoc['role'] ?? '',
          "firstName": userDoc['firstName'] ?? '',
        };
      }

      throw Exception("User data not found");
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Login failed");
    }
  }

  /// Google Sign-In with FCM token
  Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final firebaseResponse = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = firebaseResponse.user;

      if (user != null) {
        await updateUserFCMToken(user.uid);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Google Sign-In failed");
    } on GoogleSignInException catch (e) {
      throw Exception('Google Sign-In error: ${e.code} ${e.description}');
    } catch (e) {
      throw Exception('Unknown error: $e');
    }
  }

  Future<void> updateUserFCMToken(String uid) async {
    try {
      String? fcmToken = await _messaging.getToken();

      DocumentSnapshot orgDoc = await _firestore
          .collection('organizers')
          .doc(uid)
          .get();
      if (orgDoc.exists) {
        await _firestore.collection('organizers').doc(uid).update({
          'fcmToken': fcmToken,
          'lastActive': FieldValue.serverTimestamp(),
        });
        return;
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': fcmToken,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      log('Error updating FCM token: $e');
    }
  }

  Future<List<String>> getAllFCMTokens() async {
    try {
      List<String> allTokens = [];

      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in userSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['fcmToken'] != null) {
          allTokens.add(data['fcmToken']);
        }
      }

      QuerySnapshot orgSnapshot = await _firestore
          .collection('organizers')
          .where('fcmToken', isNotEqualTo: null)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in orgSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['fcmToken'] != null) {
          allTokens.add(data['fcmToken']);
        }
      }

      return allTokens;
    } catch (e) {
      log('Error getting FCM tokens: $e');
      return [];
    }
  }

  Future<List<String>> getUsersFCMTokens() async {
    try {
      QuerySnapshot userSnapshot = await _firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .where('isActive', isEqualTo: true)
          .get();

      List<String> tokens = [];
      for (var doc in userSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['fcmToken'] != null) {
          tokens.add(data['fcmToken']);
        }
      }
      return tokens;
    } catch (e) {
      log('Error getting user tokens: $e');
      return [];
    }
  }

  Future<List<String>> getOrganizersFCMTokens() async {
    try {
      QuerySnapshot orgSnapshot = await _firestore
          .collection('organizers')
          .where('fcmToken', isNotEqualTo: null)
          .where('isActive', isEqualTo: true)
          .get();

      List<String> tokens = [];
      for (var doc in orgSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['fcmToken'] != null) {
          tokens.add(data['fcmToken']);
        }
      }
      return tokens;
    } catch (e) {
      log('Error getting organizer tokens: $e');
      return [];
    }
  }

  User? get currentUser => _auth.currentUser;

  get userId => null;

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await removeFCMToken(user.uid);
      }
      await _auth.signOut();
    } catch (e) {
      log('Error during sign out: $e');
    }
  }

  Future<void> removeFCMToken(String uid) async {
    try {
      DocumentSnapshot orgDoc = await _firestore
          .collection('organizers')
          .doc(uid)
          .get();
      if (orgDoc.exists) {
        await _firestore.collection('organizers').doc(uid).update({
          'fcmToken': FieldValue.delete(),
          'isActive': false,
        });
        return;
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (userDoc.exists) {
        await _firestore.collection('users').doc(uid).update({
          'fcmToken': FieldValue.delete(),
          'isActive': false,
        });
      }
    } catch (e) {
      log('Error removing FCM token: $e');
    }
  }

  Future<void> joinEvent(DocumentSnapshot eventDoc) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final myEventsRef = userDocRef.collection('myEvents').doc(eventDoc.id);

    await myEventsRef.set({
      'name': eventDoc['name'],
      'date': eventDoc['date'],
      'location': eventDoc['location'],
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveEvent(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDocRef = _firestore.collection('users').doc(user.uid);
    await userDocRef.collection('myEvents').doc(id).delete();
  }

  Future<void> saveUserFromGoogle(User user) async {}
}
