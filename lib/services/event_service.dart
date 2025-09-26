import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _convertImageToBase64(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        log('Image file not found at path: $imagePath');
        return null;
      }

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      log('Image converted to Base64 (length: ${base64String.length})');
      return base64String;
    } catch (e) {
      log('Error converting image to Base64: $e');
      rethrow;
    }
  }

  Future<String> addEvent({
    required String name,
    required String date,
    required String location,
    required String description,
    String? imagePath,
    String? organizer,
    String? organizerId,
    required String time,
  }) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final creatorId = currentUser.uid;
      final creatorEmail = currentUser.email;

      log('=== EVENT SERVICE DEBUG ===');
      log('Current User UID: $creatorId');

      String? imageBase64;
      if (imagePath != null && imagePath.isNotEmpty) {
        imageBase64 = await _convertImageToBase64(imagePath);
        if (imageBase64 == null) {
          log(
            'Warning: Image path provided but Base64 conversion failed or file not found.',
          );
        }
      }

      final eventData = <String, dynamic>{
        'name': name.trim(),
        'date': date.trim(),
        'location': location.trim(),
        'description': description.trim(),
        'time': time.trim(),
        'organizer': organizer?.isNotEmpty == true ? organizer : creatorId,
        'organizerId': organizerId?.isNotEmpty == true
            ? organizerId
            : creatorId,
        'organizerEmail': creatorEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (imageBase64 != null) 'imageBase64': imageBase64,
      };

      log('Event data to be saved: ${eventData.keys}');

      final docRef = await _firestore.collection('events').add(eventData);

      log('Event saved with ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      log('Error adding event: $e');
      rethrow;
    }
  }

  Future<String> addEventWithCreatorInfo({
    required String name,
    required String date,
    required String location,
    required String description,
    required String time,
    String? imagePath,
    String? createdBy,
    String? creatorEmail,
    String? organizer,
    String? organizerId,
  }) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final finalCreatorId = createdBy ?? currentUser.uid;
      final finalCreatorEmail = creatorEmail ?? currentUser.email;

      log('=== ENHANCED EVENT SERVICE DEBUG ===');
      log('Final Creator ID: $finalCreatorId');

      String? imageBase64;
      if (imagePath != null && imagePath.isNotEmpty) {
        imageBase64 = await _convertImageToBase64(imagePath);
        if (imageBase64 == null) {
          log(
            'Warning: Image path provided but Base64 conversion failed or file not found.',
          );
        }
      }

      final eventData = <String, dynamic>{
        'name': name.trim(),
        'date': date.trim(),
        'location': location.trim(),
        'description': description.trim(),
        'time': time.trim(),
        'organizer': organizer?.isNotEmpty == true ? organizer : finalCreatorId,
        'organizerId': organizerId?.isNotEmpty == true
            ? organizerId
            : finalCreatorId,
        'organizerEmail': finalCreatorEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (imageBase64 != null) 'imageBase64': imageBase64,
        'authProvider': currentUser.providerData.isNotEmpty
            ? currentUser.providerData.first.providerId
            : 'unknown',
        'displayName': currentUser.displayName,
      };

      log('Enhanced event data: ${eventData.keys}');

      final docRef = await _firestore.collection('events').add(eventData);

      log('Enhanced event saved with ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      log('Error in enhanced event creation: $e');
      rethrow;
    }
  }

  Future<bool> verifyEventCreator(String eventId, String userId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;

      final creatorIds = [
        data['createdBy'],
        data['creator'],
        data['userId'],
        data['organizer'],
        data['organizerId'],
      ];

      final creatorEmails = [
        data['creatorEmail'],
        data['organizerEmail'],
        data['email'],
      ];

      final currentUser = _auth.currentUser;

      if (creatorIds.contains(userId)) return true;

      if (currentUser?.email != null &&
          creatorEmails.contains(currentUser!.email)) {
        return true;
      }

      return false;
    } catch (e) {
      log('Error verifying creator: $e');
      return false;
    }
  }

  Future<void> updateEvent({
    required String eventId,
    required String name,
    required String date,
    required String location,
    required String description,
    String? imagePath,
    required String time,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final isCreator = await verifyEventCreator(eventId, currentUser.uid);
      if (!isCreator) {
        throw Exception('Only the event creator can update this event');
      }

      String? imageBase64;
      if (imagePath != null && imagePath.isNotEmpty) {
        imageBase64 = await _convertImageToBase64(imagePath);
      }

      final updateData = <String, dynamic>{
        'name': name.trim(),
        'date': date.trim(),
        'location': location.trim(),
        'description': description.trim(),
        'time': time.trim(), 
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageBase64 != null) {
        updateData['imageBase64'] = imageBase64;
      }

      await _firestore.collection('events').doc(eventId).update(updateData);

      log('Event updated successfully: $eventId');
    } catch (e) {
      log('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final isCreator = await verifyEventCreator(eventId, currentUser.uid);
      if (!isCreator) {
        throw Exception('Only the event creator can delete this event');
      }

      await _firestore.collection('events').doc(eventId).delete();

      log('Event deleted successfully: $eventId');
    } catch (e) {
      log('Error deleting event: $e');
      rethrow;
    }
  }
}
