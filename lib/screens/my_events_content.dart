import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/services/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

class MyEventsContent extends ConsumerStatefulWidget {
  final bool? isOrganizer;
  const MyEventsContent({super.key, required this.isOrganizer});

  @override
  ConsumerState<MyEventsContent> createState() => _MyEventsContentState();
}

class _MyEventsContentState extends ConsumerState<MyEventsContent> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("my events"),
        leading: widget.isOrganizer == true
            ? IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.push(
                    Routes.addEvent,
                    extra: {
                      'organizer': '', 
                    },
                  );
                },
              )
            : null,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: CustomSearchDelegate(
                      isOrganizer: widget.isOrganizer,
                      ref: ref,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(widget.isOrganizer! ? 'organizers' : 'users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No data found."));
          }

          log(userId);

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final joinedEventIds = List<String>.from(
            userData['joinedEvents'] ?? [],
          );

          if (widget.isOrganizer!) {
            return _buildOrganizerSections(joinedEventIds, userId);
          } else {
            return _buildUserEvents(joinedEventIds);
          }
        },
      ),
    );
  }

  Widget _buildOrganizerSections(List<String> joinedEventIds, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('organizerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, createdEventsSnap) {
        if (createdEventsSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final createdEvents = createdEventsSnap.hasData
            ? createdEventsSnap.data!.docs
            : <QueryDocumentSnapshot>[];

        return StreamBuilder<QuerySnapshot>(
          stream: joinedEventIds.isNotEmpty
              ? FirebaseFirestore.instance
                    .collection('events')
                    .where(FieldPath.documentId, whereIn: joinedEventIds)
                    .snapshots()
              : const Stream.empty(),
          builder: (context, joinedEventsSnap) {
            if (joinedEventsSnap.connectionState == ConnectionState.waiting &&
                joinedEventIds.isNotEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final joinedEvents = joinedEventsSnap.hasData
                ? joinedEventsSnap.data!.docs
                : <QueryDocumentSnapshot>[];

            final filteredJoinedEvents = joinedEvents
                .where(
                  (event) =>
                      !createdEvents.any((created) => created.id == event.id),
                )
                .toList();

            if (createdEvents.isEmpty && filteredJoinedEvents.isEmpty) {
              return const Center(
                child: Text(
                  "You haven't created or joined any events yet.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 157, 191, 207),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (createdEvents.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Created Events',
                      Icons.create,
                      Colors.green,
                    ),
                    _buildEventsList(createdEvents),
                    const SizedBox(height: 20),
                  ],
                  if (filteredJoinedEvents.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Joined Events',
                      Icons.event_available,
                      Colors.blue,
                    ),
                    _buildEventsList(filteredJoinedEvents),
                    const SizedBox(height: 20),
                  ],
                  if (createdEvents.isNotEmpty && filteredJoinedEvents.isEmpty)
                    _buildEmptySection(
                      'joined',
                      Icons.event_available,
                      Colors.blue,
                    ),
                  if (createdEvents.isEmpty && filteredJoinedEvents.isNotEmpty)
                    _buildEmptySection('created', Icons.create, Colors.green),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String type, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withOpacity(0.6), size: 48),
            const SizedBox(height: 8),
            Text(
              type == 'created'
                  ? "You haven't created any events yet."
                  : "You haven't joined any events yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserEvents(List<String> joinedEventIds) {
    if (joinedEventIds.isEmpty) {
      return const Center(
        child: Text(
          "You haven't joined any events yet.",
          style: TextStyle(
            fontSize: 18,
            color: Color.fromARGB(255, 157, 191, 207),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where(FieldPath.documentId, whereIn: joinedEventIds)
          .snapshots(),
      builder: (context, eventSnap) {
        if (eventSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!eventSnap.hasData || eventSnap.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No joined events found.",
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 157, 191, 207),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'Joined Events',
                Icons.event_available,
                Colors.blue,
              ),
              _buildEventsList(eventSnap.data!.docs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventsList(List<QueryDocumentSnapshot> events) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventData = event.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Consumer(
            builder: (context, ref, child) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                title: Text(
                  eventData['name'] ?? 'No title',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          eventData['date'] ?? 'No date',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (eventData['location'] != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              eventData['location'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      53,
                      137,
                      158,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color.fromARGB(255, 53, 137, 158),
                    size: 18,
                  ),
                ),
                onTap: () {
                  context.go(
                    '${Routes.eventDetail}/${event.id}',
                    extra: {
                      'event': event,
                      'isOrganizer': widget.isOrganizer ?? false,
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final bool? isOrganizer;
  final WidgetRef ref;

  CustomSearchDelegate({required this.isOrganizer, required this.ref});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: () => query = "", icon: const Icon(Icons.clear)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text("Search result for $query"));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Center(child: Text("Suggestions for $query"));
  }
}
