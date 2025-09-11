import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventActionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> isUserJoined(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .doc(user.uid)
        .get();

    return doc.exists;
  }

  Future<void> joinEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user is logged in.");

    String firstName = '';
    String lastName = '';
    String email = user.email ?? '';

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final organizerDoc = await _firestore
        .collection('organizers')
        .doc(user.uid)
        .get();

    Map<String, dynamic>? data;
    String targetCollection = '';

    if (userDoc.exists) {
      data = userDoc.data();
      targetCollection = 'users';
    } else if (organizerDoc.exists) {
      data = organizerDoc.data();
      targetCollection = 'organizers';
    }

    firstName = data?['firstName'] ?? '';
    lastName = data?['lastName'] ?? '';
    email = data?['email'] ?? email;

    if (firstName.isEmpty && lastName.isEmpty) {
      final parts = (user.displayName ?? '').split(" ");
      firstName = parts.isNotEmpty ? parts.first : 'Unknown';
      lastName = parts.length > 1 ? parts.sublist(1).join(" ") : '';
    }

    final eventDocRef = _firestore.collection('events').doc(eventId);

    final participantData = {
      'uid': user.uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'joinedAt': FieldValue.serverTimestamp(),
    };

    await eventDocRef
        .collection('participants')
        .doc(user.uid)
        .set(participantData, SetOptions(merge: true));

    if (targetCollection.isNotEmpty) {
      await _firestore.collection(targetCollection).doc(user.uid).set({
        'joinedEvents': FieldValue.arrayUnion([eventId]),
      }, SetOptions(merge: true));
    }
  }

  Future<void> leaveEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user is logged in.");

    final eventDocRef = _firestore.collection('events').doc(eventId);

    await eventDocRef.collection('participants').doc(user.uid).delete();

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final organizerDoc = await _firestore
        .collection('organizers')
        .doc(user.uid)
        .get();

    String targetCollection = '';

    if (userDoc.exists) {
      targetCollection = 'users';
    } else if (organizerDoc.exists) {
      targetCollection = 'organizers';
    }

    if (targetCollection.isNotEmpty) {
      await _firestore.collection(targetCollection).doc(user.uid).update({
        'joinedEvents': FieldValue.arrayRemove([eventId]),
      });
    }
  }
}
