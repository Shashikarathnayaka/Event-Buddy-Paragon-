import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class EventDetailScreen extends StatelessWidget {
  final DocumentSnapshot eventDoc;
  const EventDetailScreen({super.key, required this.eventDoc});

  Future<DocumentSnapshot?> _getOrganizer(String? organizerId) async {
    if (organizerId == null || organizerId.isEmpty) {
      return null;
    }
    return await FirebaseFirestore.instance
        .collection('organizers')
        .doc(organizerId)
        .get();
  }

  get bottomNavigationBar => null;

  Widget _imageFromBase64(String base64String) {
    try {
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      Uint8List bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 80);
    }
  }

  Future<Map<String, String?>> _resolveImageInfo(
    Map<String, dynamic> data,
  ) async {
    String? raw = (data['imageUrl'] ?? data['image'] ?? data['imageBase64'])
        ?.toString();
    if (raw == null || raw.isEmpty) return {'url': null, 'base64': null};

    if (raw.startsWith('http')) return {'url': raw, 'base64': null};

    if (raw.contains('base64')) {
      final b64 = raw.split(',').last;
      return {'url': null, 'base64': b64};
    }

    try {
      if (raw.startsWith('gs://')) {
        final url = await FirebaseStorage.instance
            .refFromURL(raw)
            .getDownloadURL();
        return {'url': url, 'base64': null};
      }

      final path = raw.startsWith('/') ? raw.substring(1) : raw;
      try {
        final url = await FirebaseStorage.instance
            .ref()
            .child(path)
            .getDownloadURL();
        return {'url': url, 'base64': null};
      } catch (e) {
        if (raw.length > 100) {
          return {'url': null, 'base64': raw};
        }
      }
    } catch (e) {
      print('Error resolving image info: $e');
    }

    return {'url': null, 'base64': null};
  }

  @override
  Widget build(BuildContext context) {
    final data = (eventDoc.data() as Map<String, dynamic>?) ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data['name'] ?? 'Event Detail',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 53, 137, 158),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Confirm delete'),
                  content: const Text('Do you want to delete this event?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await eventDoc.reference.delete();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Event deleted')),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Delete failed: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<Map<String, String?>>(
              future: _resolveImageInfo(data),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                final info = snap.data ?? {'url': null, 'base64': null};
                final url = info['url'];
                final base64 = info['base64'];

                if (url != null && url.isNotEmpty) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => Image.asset(
                        'assets/images/event_banner.jpg',
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                } else if (base64 != null && base64.isNotEmpty) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageFromBase64(base64),
                  );
                } else {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/event_banner.jpg',
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 16),
            Text(
              data['name'] ?? 'No title',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(data['date'] ?? 'No date'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(data['location'] ?? 'No location')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data['description'] ?? 'No description',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Organizer: ${data['organizer'] ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            FutureBuilder<DocumentSnapshot?>(
              future: _getOrganizer(data['organizer']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("Organizer details not available");
                }
                if (!snapshot.data!.exists) {
                  return const Text("Organizer not found");
                }

                final organizerData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                final firstName = organizerData['firstName'] ?? '';
                final lastName = organizerData['lastName'] ?? '';
                final email = organizerData['email'] ?? '-';
                // final role = organizerData['role'] ?? '-';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Organizer: ${firstName.isNotEmpty || lastName.isNotEmpty ? "$firstName $lastName" : '-'}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("Email: $email"),
                    // Text("Role: $role"),
                  ],
                );
              },
            ),

            // FutureBuilder<DocumentSnapshot?>(
            //   future: _getOrganizer(organizerId),
            //   builder: (context, snapshot) {
            //     if (snapshot.connectionState == ConnectionState.waiting) {
            //       return const CircularProgressIndicator();
            //     }
            //     if (!snapshot.hasData || snapshot.data == null) {
            //       return const Text("Organizer details not available");
            //     }
            //     if (!snapshot.data!.exists) {
            //       return const Text("Organizer not found");
            //     }

            //     final organizerData =
            //         snapshot.data!.data() as Map<String, dynamic>? ?? {};

            //     final firstName = organizerData['firstName'] ?? '-';
            //     final lastName = organizerData['lastName'] ?? '-';
            //     final email = organizerData['email'] ?? '-';
            //     final role = organizerData['role'] ?? '-';

            //     return Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           "Organizer: $firstName $lastName",
            //           style: const TextStyle(
            //             fontSize: 16,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //         Text("Email: $email"),
            //         Text("Role: $role"),
            //       ],
            //     );
            //   },
            // ),
            const SizedBox(height: 8),
            Text(
              'Created: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString() : '-'}',
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 43, 203, 158),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: const Text(
                  "Join",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    // fontStyle: FontStyle.talic,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {},
                child: const Text(
                  "Leave",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    // fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
