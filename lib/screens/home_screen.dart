import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/navigation_screen.dart';
import 'package:event_buddy/services/join_leave_event.dart';
import 'package:event_buddy/services/push_notification_service.dart';
import 'package:event_buddy/services/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

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
    // final eventActionService = ref.read(eventActionServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          if (widget.isOrganizer == true)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push(
                  Routes.addEvent,
                ); 
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(
                  ref: ref,
                  isOrganizer: widget.isOrganizer,
                ),
              );
            },
          ),
        ],
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final data = event.data() as Map<String, dynamic>;

              return Card(
                color: const Color(0xFF1C1A27),
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
                    context.go(
                      '${Routes.eventDetail}/${event.id}',
                      extra: {
                        'event': event,
                        'isOrganizer': widget.isOrganizer ?? false,
                      },
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
                      close(context, null);
                      context.push('/event/${event.id}', extra: event);
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
                      close(context, null);
                      context.push('/event/${event.id}', extra: event);
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
