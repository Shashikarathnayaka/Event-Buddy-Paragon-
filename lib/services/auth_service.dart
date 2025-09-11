import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        final Map<String, dynamic> userData = {
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "dob": dob,
          "role": role,
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
  ///// Login with email & password--------------------------------------------------

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
      DocumentSnapshot orgDoc = await _firestore
          .collection('organizers')
          .doc(uid)
          .get();
      if (orgDoc.exists) {
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

  /// Google Sign-In
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
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Google Sign-In failed");
    } on GoogleSignInException catch (e) {
      throw Exception('Google Sign-In error: ${e.code} ${e.description}');
    } catch (e) {
      throw Exception('Unknown error: $e');
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
    await _auth.signOut();
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

  // Future<Future<Map<String, dynamic>?>> getUserData(String uid) async {}
}



