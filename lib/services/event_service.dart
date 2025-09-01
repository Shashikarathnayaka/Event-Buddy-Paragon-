import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EventService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Future<void> addEvent({
  //   required String name,
  //   required String date,
  //   required String location,
  //   required String description,
  //   String? imagePath,
  //   String? organizer,
  // }) async {
  //   String? imageUrl;

  //   if (imagePath != null && imagePath.isNotEmpty) {
  //     final file = File(imagePath);
  //     final ext = p.extension(imagePath);
  //     final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
  //     final ref = _storage.ref().child('event_images/$fileName');

  //     await ref.putFile(file);
  //     imageUrl = await ref.getDownloadURL();
  //   }

  //   await _db.collection('events').add({
  //     'name': name,
  //     'description': description,
  //     'date': date,
  //     'location': location,
  //     'imageUrl': imageUrl,
  //     'organizer': organizer,
  //     'createdAt': FieldValue.serverTimestamp(),
  //   });
  // }

  Future<void> addEvent({
    required String name,
    required String date,
    required String location,
    required String description,
    String? imagePath,
    required String? organizer,
    required String organizerId,
  }) async {
    String? base64Image;
    print(organizer);
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64Image = base64Encode(bytes);
      } else {
        print(" File not found at path: $imagePath");
      }
    }

    await _db.collection('events').add({
      'name': name,
      'description': description,
      'date': date,
      'location': location,
      'imageBase64': base64Image,
      'organizer': organizer,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllEvents() {
    return _db
        .collection('events')
        .orderBy('createdAt', descending: true)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? {},
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }
}
