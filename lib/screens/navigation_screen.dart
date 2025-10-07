

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/event_detail_screen.dart';
import 'package:event_buddy/screens/home_screen.dart';
import 'package:event_buddy/screens/my_events_content.dart';
import 'package:event_buddy/screens/profile_screen.dart';
import 'package:event_buddy/services/join_leave_event.dart';
import 'package:event_buddy/theme/app_colors.dart';
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

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25.0),
          topRight: Radius.circular(25.0),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.card,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note),
              label: 'My Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedPageIndex,
          onTap: _onItemTapped,
        ),
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
        backgroundColor: Color.fromRGBO(102, 126, 234, 1.0),
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
        // ignore: deprecated_member_use
        fillColor: Colors.white.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        constraints: BoxConstraints(maxWidth: double.infinity, minHeight: 40),
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
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('events')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromRGBO(102, 126, 234, 1.0),
            ),
          );
        }

        var results = snapshot.data!.docs;
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
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
              ),
            );
          },
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

    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('events')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromRGBO(102, 126, 234, 1.0),
            ),
          );
        }

        var results = snapshot.data!.docs;
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
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
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
              ),
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
