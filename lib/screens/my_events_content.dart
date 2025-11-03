import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/navigation_screen.dart';
import 'package:event_buddy/services/routes.dart';
import 'package:event_buddy/theme/app_colors.dart';
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
                  context.push(Routes.addEvent, extra: {'organizer': ''});
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
                  context.push(
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
  final WidgetRef ref;
  final bool? isOrganizer;

  CustomSearchDelegate({required this.ref, this.isOrganizer});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        constraints: const BoxConstraints(
          maxWidth: double.infinity,
          minHeight: 40,
        ),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            ref.read(searchQueryProvider.notifier).clear();
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Search events...',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromRGBO(113, 128, 150, 1.0),
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(eventSearchProvider(query));

        return searchResults.when(
          data: (results) {
            if (results.isEmpty) {
              return const Center(
                child: Text(
                  'No events found.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromRGBO(113, 128, 150, 1.0),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: results.length,
              itemBuilder: (context, index) {
                var event = results[index];
                var data = event.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromRGBO(102, 126, 234, 0.1),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Color.fromRGBO(102, 126, 234, 1.0),
                      ),
                    ),
                    title: Text(
                      data['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      data['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () {
                      // Store router reference before closing
                      final router = GoRouter.of(context);

                      // Close search delegate
                      close(context, null);

                      // Navigate after search is closed
                      Future.microtask(() {
                        router.push(
                          '/event/${event.id}',
                          extra: {
                            'event': event,
                            'isOrganizer': isOrganizer ?? false,
                          },
                        );
                      });
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color.fromRGBO(102, 126, 234, 1.0),
            ),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error: ${error.toString()}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Type to search events...',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromRGBO(113, 128, 150, 1.0),
          ),
        ),
      );
    }

    return Consumer(
      builder: (context, ref, child) {
        final searchResults = ref.watch(eventSearchProvider(query));

        return searchResults.when(
          data: (results) {
            if (results.isEmpty) {
              return const Center(
                child: Text(
                  'No matching events found.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromRGBO(113, 128, 150, 1.0),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: results.length,
              itemBuilder: (context, index) {
                var event = results[index];
                var data = event.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromRGBO(102, 126, 234, 0.1),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Color.fromRGBO(102, 126, 234, 1.0),
                      ),
                    ),
                    title: Text(
                      data['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      data['description'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () {
                      // Store router reference before closing
                      final router = GoRouter.of(context);

                      // Close search delegate
                      close(context, null);

                      // Navigate after search is closed
                      Future.microtask(() {
                        router.push(
                          '/event/${event.id}',
                          extra: {
                            'event': event,
                            'isOrganizer': isOrganizer ?? false,
                          },
                        );
                      });
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color.fromRGBO(102, 126, 234, 1.0),
            ),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error: ${error.toString()}',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      },
    );
  }

  Widget buildImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const Icon(Icons.image_not_supported);
    }
    try {
      Uint8List bytes = base64Decode(base64String);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      return const Icon(Icons.error);
    }
  }
}

extension SearchExtension on WidgetRef {
  void showEventSearch(BuildContext context, bool? isOrganizer) {
    showSearch(
      context: context,
      delegate: CustomSearchDelegate(ref: this, isOrganizer: isOrganizer),
    );
  }
}
