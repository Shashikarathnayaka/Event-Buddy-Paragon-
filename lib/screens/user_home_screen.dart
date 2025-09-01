import 'package:flutter/material.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key, required String userName});

  @override
  State<UserHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<UserHomeScreen> {
  int _selectedPageIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _HomeContent(),
    _ProfileContent(),
  ];

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
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedPageIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EventBuddy'),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All Events'),
              Tab(text: 'My Events'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AllEventsTab(),
            _MyEventsTab(),
          ],
        ),
      ),
    );
  }
}

class _AllEventsTab extends StatelessWidget {
  const _AllEventsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "user home screen ",
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}

class _MyEventsTab extends StatelessWidget {
  const _MyEventsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Your Events will be displayed here.",
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "Profile information will be displayed here.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
