import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/add_event_screen.dart';
import 'package:event_buddy/screens/event_detail_screen.dart';
import 'package:event_buddy/services/join_leave_event.dart';
import 'package:event_buddy/services/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

// Providers
final eventsStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance.collection('events').snapshots();
});

final eventActionServiceProvider = Provider<EventActionService>((ref) {
  return EventActionService();
});

class HomeScreen extends ConsumerStatefulWidget {
  final bool? isOrganizer;
  const HomeScreen({super.key, required this.isOrganizer});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _setupNotificationBroadcast();
  }

  _setupNotificationBroadcast() async {
    PushNotificationService.subscribeToTopic('all');
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsyncValue = ref.watch(eventsStreamProvider);
    final eventActionService = ref.read(eventActionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        leading: widget.isOrganizer == true
            ? IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEventScreen(organizer: ''),
                    ),
                  );
                },
              )
            : null,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: eventsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.accentRed),
          ),
        ),
        data: (snapshot) {
          if (snapshot.docs.isEmpty) {
            return const Center(
              child: Text(
                "All Events will be displayed here.",
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
              ),
            );
          }

          final events = snapshot.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final data = event.data() as Map<String, dynamic>;

              return Card(
                color: AppColors.card,
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading:
                      (data['imageBase64'] != null &&
                          data['imageBase64'].toString().isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            base64Decode(data['imageBase64']),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : (data['imageUrl'] != null &&
                            data['imageUrl'].toString().isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            data['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.event,
                          size: 50,
                          color: AppColors.textSecondary,
                        ),
                  title: Text(
                    data['name'] ?? 'No Name',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['description'] ?? 'No Description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            data['date'] ?? 'No Date',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              data['location'] ?? 'No Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(
                          isOrganizer: widget.isOrganizer,
                          eventDoc: event,
                          joinLeaveService: eventActionService,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
