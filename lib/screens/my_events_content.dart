import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/event_detail_screen.dart';
import 'package:event_buddy/screens/navigation_screen.dart';
import 'package:event_buddy/services/join_leave_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: const Text(
          'My Events',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 53, 137, 158),
        foregroundColor: Colors.white,
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
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No data found."));
          }

          print(userId);

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final joinedEventIds = List<String>.from(
            userData['joinedEvents'] ?? [],
          );

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

              final events = eventSnap.data!.docs;

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final eventData = event.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(eventData['name'] ?? 'No title'),
                      subtitle: Text(eventData['date'] ?? 'No date'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(
                              isOrganizer: widget.isOrganizer,
                              eventDoc: event,
                              joinLeaveService: EventActionService(),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
