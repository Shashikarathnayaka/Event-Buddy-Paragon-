import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserData({
    required User user,
    required String role,
    required String firstName,
    required String lastName,
    String? dob,
  }) async {
    try {
      String collectionName = role == "User" ? "users" : "organizers";

      DocumentReference userDocRef = _firestore
          .collection(collectionName)
          .doc(user.uid);

      DocumentSnapshot docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        await userDocRef.set({
          "firstName": firstName,
          "lastName": lastName,
          "email": user.email,
          "dob": dob ?? "",
          "role": role,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }
}
