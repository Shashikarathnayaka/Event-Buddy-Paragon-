import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/event_detail_screen.dart';
import 'package:event_buddy/screens/home_screen.dart';
import 'package:event_buddy/screens/my_events_content.dart';
import 'package:event_buddy/screens/profile_screen.dart';
import 'package:event_buddy/services/join_leave_event.dart';
import 'package:flutter/material.dart';

class NavigationScreen extends StatefulWidget {
  final bool? isOrganizer;
  const NavigationScreen({
    super.key,
    required String userName,
    this.isOrganizer,
  });

  @override
  State<NavigationScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<NavigationScreen> {
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(isOrganizer: widget.isOrganizer ?? true),
      MyEventsContent(isOrganizer: widget.isOrganizer ?? true),
      ProfileScreen(),
    ];
  }

  int _selectedPageIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'My Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedPageIndex,
        selectedItemColor: Color.fromARGB(255, 53, 137, 158),
        onTap: _onItemTapped,
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool? isOrganizer;

  CustomSearchDelegate({this.isOrganizer});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 59, 155, 179),
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
        fillColor: const Color.fromARGB(82, 229, 235, 235),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        constraints: BoxConstraints(maxWidth: double.infinity, minHeight: 40),
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
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(child: Text('Search events...'));
    }
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('events')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var results = snapshot.data!.docs;
        if (results.isEmpty) return Center(child: Text('No events found.'));

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            var event = results[index];
            return ListTile(
              title: Text(event['name'] ?? 'No Name'),
              subtitle: Text(event['description'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(
                      isOrganizer: isOrganizer,
                      eventDoc: event,
                      joinLeaveService: EventActionService(),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('events')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var results = snapshot.data!.docs;
        if (results.isEmpty) {
          return Center(child: Text('No matching events found.'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            var event = results[index];
            return ListTile(
              title: Text(event['name'] ?? 'No Name'),
              subtitle: Text(event['description'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(
                      isOrganizer: isOrganizer,
                      eventDoc: event,
                      joinLeaveService: EventActionService(),
                    ),
                  ),
                );
              },
            );
          },
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
