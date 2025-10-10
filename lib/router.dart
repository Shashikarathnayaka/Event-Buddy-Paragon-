import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/screens/splash_screen.dart';
import 'package:event_buddy/screens/home_screen.dart';
import 'package:event_buddy/screens/add_event_screen.dart';
import 'package:event_buddy/screens/event_detail_screen.dart';
import 'package:event_buddy/screens/my_events_content.dart';
import 'package:event_buddy/screens/profile_screen.dart';
import 'package:event_buddy/services/join_leave_event.dart';
import 'package:event_buddy/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});


final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',

    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.uri.path == '/auth';
      final isSplash = state.uri.path == '/splash';

      if (isSplash) return null;

      if (!isLoggedIn && !isLoggingIn) {
        return '/auth';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null; 
    },

    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text(
              "Login/Register Screen",
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return NavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final isOrganizer = extra?['isOrganizer'] as bool? ?? false;

              return NoTransitionPage(
                child: HomeScreen(isOrganizer: isOrganizer),
              );
            },
          ),
          GoRoute(
            path: '/my-events',
            name: 'myEvents',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final isOrganizer = extra?['isOrganizer'] as bool? ?? false;

              return NoTransitionPage(
                child: MyEventsContent(isOrganizer: isOrganizer),
              );
            },
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ProfileScreen());
            },
          ),
        ],
      ),

      GoRoute(
        path: '/organizer-home',
        name: 'organizerHome',
        builder: (context, state) => const HomeScreen(isOrganizer: true),
      ),

      GoRoute(
        path: '/add-event',
        name: 'addEvent',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final organizerId = extra?['organizerId'] as String? ?? '';

          return AddEventScreen(organizer: organizerId);
        },
      ),

      GoRoute(
        path: '/event/:id',
        name: 'eventDetail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final event = extra?['event'];
          final isOrganizer = extra?['isOrganizer'] ?? false;

          return EventDetailScreen(
            isOrganizer: isOrganizer,
            eventDoc: event,
            joinLeaveService: EventActionService(),
          );
        },
      ),

      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isOrganizer = extra?['isOrganizer'] as bool?;

          return SearchScreen(isOrganizer: isOrganizer);
        },
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            const Text(
              '404 - Page not found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.path,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});


class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    int selectedIndex = 0;
    if (location.startsWith('/home')) {
      selectedIndex = 0;
    } else if (location.startsWith('/my-events')) {
      selectedIndex = 1;
    } else if (location.startsWith('/profile')) {
      selectedIndex = 2;
    }

    return Scaffold(
      body: child,
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
          currentIndex: selectedIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/my-events');
                break;
              case 2:
                context.go('/profile');
                break;
            }
          },
        ),
      ),
    );
  }
}


class SearchScreen extends ConsumerStatefulWidget {
  final bool? isOrganizer;

  const SearchScreen({super.key, this.isOrganizer});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search events...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 6,
            ),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() => _query = value);
          },
        ),
      ),
      body: Center(
        child: Text(
          _query.isEmpty ? 'Type to search events...' : 'Searching: $_query',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}


extension NavigationExtension on BuildContext {
  void navigateToEventDetail(
    QueryDocumentSnapshot eventDoc,
    bool? isOrganizer,
  ) {
    push(
      '/event/${eventDoc.id}',
      extra: {'event': eventDoc, 'isOrganizer': isOrganizer},
    );
  }

  void showEventSearch(bool? isOrganizer) {
    push('/search', extra: {'isOrganizer': isOrganizer});
  }

  void navigateToAddEvent(String organizerId) {
    push('/add-event', extra: {'organizerId': organizerId});
  }

  void navigateAfterLogin(bool isOrganizer) {
    if (isOrganizer) {
      go('/organizer-home');
    } else {
      go('/home');
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      go('/auth');
    }
  }
}
