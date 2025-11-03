import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/services/join_leave_event.dart';
import 'package:event_buddy/services/routes.dart';
import 'package:event_buddy/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventDetailScreen extends StatefulWidget {
  final bool? isOrganizer;
  final DocumentSnapshot eventDoc;
  final String eventId;
  final EventActionService joinLeaveService;

  const EventDetailScreen({
    super.key,
    required this.isOrganizer,
    required this.eventDoc,
    required this.eventId,
    required this.joinLeaveService,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventActionService _eventService = EventActionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isEventCreator(Map<String, dynamic> eventData) {
    final currentUserId = _auth.currentUser?.uid;

    // Check all possible organizer field names
    final eventOrganizerId =
        eventData['organizerId'] ??
        eventData['organizer'] ??
        eventData['createdBy'] ??
        eventData['userId'] ??
        eventData['creator'];

    debugPrint('=== IS CREATOR CHECK ===');
    debugPrint('Current User ID: $currentUserId');
    debugPrint('Event Organizer ID: $eventOrganizerId');
    debugPrint('All event data keys: ${eventData.keys.toList()}');
    debugPrint('Are they equal? ${currentUserId == eventOrganizerId}');

    if (currentUserId == null || eventOrganizerId == null) {
      return false;
    }

    return currentUserId.toString() == eventOrganizerId.toString();
  }

  Future<DocumentSnapshot?> _getOrganizer(String? organizerId) async {
    debugPrint('=== GET ORGANIZER DEBUG ===');
    debugPrint('Organizer ID received: $organizerId');

    if (organizerId == null || organizerId.isEmpty) {
      debugPrint('Organizer ID is null or empty');
      return null;
    }

    try {
      var doc = await _firestore
          .collection('organizers')
          .doc(organizerId)
          .get();
      debugPrint('Organizers collection doc exists: ${doc.exists}');

      if (doc.exists) {
        debugPrint('Organizer data from organizers collection: ${doc.data()}');
        return doc;
      }

      doc = await _firestore.collection('users').doc(organizerId).get();
      debugPrint('Users collection doc exists: ${doc.exists}');

      if (doc.exists) {
        debugPrint('Organizer data from users collection: ${doc.data()}');
        return doc;
      }

      debugPrint('Organizer not found in any collection');
      return null;
    } catch (e) {
      debugPrint('Error getting organizer: $e');
      return null;
    }
  }

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
      log('Error resolving image info: $e');
    }

    return {'url': null, 'base64': null};
  }

  void _showFullScreenImage(BuildContext context, String? url, String? base64) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Background with image
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black87,
                  child: Center(
                    child: InteractiveViewer(
                      child: _buildFullScreenImage(url, base64),
                    ),
                  ),
                ),
              ),
              // Close button - positioned absolutely on top
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullScreenImage(String? url, String? base64) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/images/event_banner.jpg', fit: BoxFit.contain),
      );
    } else if (base64 != null && base64.isNotEmpty) {
      try {
        String cleanBase64 = base64;
        if (base64.contains(',')) {
          cleanBase64 = base64.split(',').last;
        }
        Uint8List bytes = base64Decode(cleanBase64);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        return const Icon(Icons.broken_image, size: 80, color: Colors.white);
      }
    } else {
      return Image.asset('assets/images/event_banner.jpg', fit: BoxFit.contain);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = (widget.eventDoc.data() as Map<String, dynamic>?) ?? {};
    final eventId = widget.eventDoc.id;
    final userId = _auth.currentUser?.uid;
    final isCreator = _isEventCreator(data);

    // Enhanced debug prints
    debugPrint('widget.isOrganizer: ${widget.isOrganizer}');
    debugPrint('isCreator: $isCreator');
    debugPrint('userId: $userId');
    debugPrint('eventId: $eventId');
    debugPrint('Event organizerId field: ${data['organizerId']}');
    debugPrint('Event organizer field: ${data['organizer']}');
    debugPrint('All event data keys: ${data.keys.toList()}');
    debugPrint('Should show edit/delete buttons: $isCreator');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
        title: Text(
          data['name'] ?? 'Event Detail',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.card,
        actions: isCreator
            ? [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () async {
                    final updated = await context.push<bool>(
                      Routes.eventEdit,
                      extra: {'eventDoc': widget.eventDoc},
                    );

                    if (updated == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Event updated successfully!'),
                          backgroundColor: Color.fromARGB(255, 34, 137, 168),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Confirm delete'),
                        content: const Text(
                          'Do you want to delete this event? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      if (!context.mounted) return;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        await widget.eventDoc.reference.delete();
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Event deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete event: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ]
            : null,
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

                Widget imageWidget;

                if (url != null && url.isNotEmpty) {
                  imageWidget = Image.network(
                    url,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Image.asset(
                      'assets/images/event_banner.jpg',
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  );
                } else if (base64 != null && base64.isNotEmpty) {
                  imageWidget = _imageFromBase64(base64);
                } else {
                  imageWidget = Image.asset(
                    'assets/images/event_banner.jpg',
                    height: 220,
                    fit: BoxFit.cover,
                  );
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      _showFullScreenImage(context, url, base64);
                    },
                    child: imageWidget,
                  ),
                );
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
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(data['time'] ?? 'No time'),
              ],
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
            const SizedBox(height: 20),
            FutureBuilder<DocumentSnapshot?>(
              future: _getOrganizer(
                data['organizerId'] ??
                    data['organizer'] ??
                    data['createdBy'] ??
                    data['userId'] ??
                    data['creator'],
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    !snapshot.data!.exists) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Organizer:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCreator)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: const Text(
                            "You are the creator of this event",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  );
                }

                final organizerData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};

                final firstName = organizerData['firstName'] ?? '';
                final lastName = organizerData['lastName'] ?? '';
                final name = organizerData['name'] ?? '';
                final email = organizerData['email'] ?? '-';

                final displayName =
                    (firstName.isNotEmpty || lastName.isNotEmpty)
                    ? "$firstName $lastName".trim()
                    : (name.isNotEmpty ? name : 'Unknown');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Organizer: $displayName",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("Email: $email"),
                    if (isCreator)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Text(
                          "You are the creator of this event",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString() : '-'}',
            ),
          ],
        ),
      ),
      bottomNavigationBar: userId == null || isCreator
          ? const SizedBox.shrink()
          : StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(userId).snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                Map<String, dynamic>? userData =
                    userSnapshot.data?.data() as Map<String, dynamic>?;

                if (userData != null) {
                  return _buildJoinLeaveButton(
                    context,
                    userData,
                    eventId,
                    true,
                  );
                }

                return StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('organizers')
                      .doc(userId)
                      .snapshots(),
                  builder: (context, orgSnapshot) {
                    if (orgSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(
                        height: 60,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final orgData =
                        orgSnapshot.data?.data() as Map<String, dynamic>?;

                    return _buildJoinLeaveButton(
                      context,
                      orgData ?? {},
                      eventId,
                      false,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildJoinLeaveButton(
    BuildContext context,
    Map<String, dynamic> data,
    String eventId,
    bool isUser,
  ) {
    final joinedEvents = (data['joinedEvents'] as List?)?.cast<String>() ?? [];
    final isJoined = joinedEvents.contains(eventId);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isJoined
              ? Colors.red
              : const Color.fromARGB(255, 43, 203, 158),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () async {
          try {
            if (isJoined) {
              await _eventService.leaveEvent(eventId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You left the event')),
              );
            } else {
              await _eventService.joinEvent(eventId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You joined the event')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        child: Text(
          isJoined ? "Leave" : "Join",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
