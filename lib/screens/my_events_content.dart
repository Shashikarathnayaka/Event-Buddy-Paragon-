import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:event_buddy/screens/event_detail_screen.dart';
import 'package:event_buddy/screens/navigation_screen.dart';
import 'package:event_buddy/services/join_leave_event.dart';

const Color _primaryColor = Color.fromRGBO(102, 126, 234, 1.0);
const Color _accentColor = Color.fromRGBO(118, 75, 162, 1.0);
const Color _newLightBackground = Color.fromRGBO(240, 244, 248, 1.0);
const Color _darkTextColor = Color.fromRGBO(113, 128, 150, 1.0);
const Color _eventGradientStart = Color.fromRGBO(255, 121, 97, 1.0);

class MyEventsContent extends StatefulWidget {
  final bool? isOrganizer;
  const MyEventsContent({super.key, required this.isOrganizer});

  @override
  State<MyEventsContent> createState() => _MyEventsContentState();
}

class _MyEventsContentState extends State<MyEventsContent> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: _newLightBackground,
      appBar: AppBar(
        title: const Text(
          'My Events',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(25.0),
            bottomRight: Radius.circular(25.0),
          ),
        ),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(isOrganizer: widget.isOrganizer),
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
            return Center(
              child: CircularProgressIndicator(color: _primaryColor),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "No data found.",
                style: TextStyle(fontSize: 18, color: _darkTextColor),
              ),
            );
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
          return Center(child: CircularProgressIndicator(color: _primaryColor));
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
              return Center(
                child: CircularProgressIndicator(color: _primaryColor),
              );
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
              return Center(
                child: Text(
                  "You haven't created or joined any events yet.",
                  style: TextStyle(fontSize: 18, color: _darkTextColor),
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
                      _primaryColor,
                    ),
                    _buildEventsList(createdEvents),
                    const SizedBox(height: 20),
                  ],

                  if (filteredJoinedEvents.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Joined Events',
                      Icons.event_available,
                      _accentColor,
                    ),
                    _buildEventsList(filteredJoinedEvents),
                    const SizedBox(height: 20),
                  ],

                  if (createdEvents.isNotEmpty && filteredJoinedEvents.isEmpty)
                    _buildEmptySection(
                      'joined',
                      Icons.event_available,
                      _accentColor,
                    ),

                  if (createdEvents.isEmpty && filteredJoinedEvents.isNotEmpty)
                    _buildEmptySection('created', Icons.create, _primaryColor),
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
          // ignore: deprecated_member_use
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          // ignore: deprecated_member_use
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // ignore: deprecated_member_use
            Icon(icon, color: color.withOpacity(0.6), size: 48),
            const SizedBox(height: 8),
            Text(
              type == 'created'
                  ? "You haven't created any events yet."
                  : "You haven't joined any events yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                // ignore: deprecated_member_use
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
      return Center(
        child: Text(
          "You haven't joined any events yet.",
          style: TextStyle(fontSize: 18, color: _darkTextColor),
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
          return Center(child: CircularProgressIndicator(color: _primaryColor));
        }
        if (!eventSnap.hasData || eventSnap.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No joined events found.",
              style: TextStyle(fontSize: 18, color: _darkTextColor),
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
                const Color.fromARGB(255, 33, 128, 184),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final eventData = event.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // ignore: deprecated_member_use
              colors: [
                _eventGradientStart,
                const Color.fromARGB(255, 41, 131, 184).withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: _eventGradientStart.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // ignore: deprecated_member_use
              splashColor: Colors.white.withOpacity(0.2),
              // ignore: deprecated_member_use
              highlightColor: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(
                      isOrganizer: widget.isOrganizer,
                      eventDoc: event,
                      joinLeaveService: EventActionService(),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventData['name'] ?? 'No title',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                eventData['date'] ?? 'No date',
                                style: TextStyle(
                                  fontSize: 13,
                                  // ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                          if (eventData['location'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    eventData['location'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      // ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
