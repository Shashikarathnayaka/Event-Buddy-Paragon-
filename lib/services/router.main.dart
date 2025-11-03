part of 'router.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute =
          state.uri.path == Routes.login ||
          state.uri.path == Routes.register ||
          state.uri.path == Routes.roleSelection;
      final isSplash = state.uri.path == Routes.splash;

      if (isSplash) return null;

      if (!isLoggedIn && !isAuthRoute) return Routes.login;

      if (isLoggedIn && isAuthRoute) return Routes.navigation;

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Register Screen
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Role Selection Screen
      GoRoute(
        path: Routes.roleSelection,
        name: 'roleSelection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RoleSelectionScreen(
            firstName: extra?['firstName'] ?? '',
            lastName: extra?['lastName'] ?? '',
            email: extra?['email'] ?? '',
            password: extra?['password'] ?? '',
            dob: extra?['dob'] ?? '',
            fromGoogle: extra?['fromGoogle'] ?? false,
          );
        },
      ),

      // Main Navigation
      GoRoute(
        path: Routes.navigation,
        name: 'navigation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final user = FirebaseAuth.instance.currentUser;
          final userName = extra?['userName'] ?? user?.displayName ?? 'User';
          final isOrganizer = extra?['isOrganizer'] ?? false;

          return NavigationScreen(userName: userName, isOrganizer: isOrganizer);
        },
      ),

      // Home Screen
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isOrganizer = extra?['isOrganizer'] ?? false;
          return HomeScreen(isOrganizer: isOrganizer);
        },
      ),

      // Profile Screen
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Events Routes
      GoRoute(
        path: Routes.myEvents,
        name: 'myEvents',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isOrganizer = extra?['isOrganizer'];
          return MyEventsContent(isOrganizer: isOrganizer);
        },
      ),
      // Add Event Routes
      GoRoute(
        path: Routes.addEvent,
        name: 'addEvent',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final organizer = extra?['organizer'] as String? ?? 'organizer';
          return AddEventScreen(organizer: organizer);
        },
      ),

      // Event Detail Route - FIXED VERSION
      GoRoute(
        path: '/event/:id',
        name: 'eventDetail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final eventId = state.pathParameters['id'] ?? '';
          final event = extra?['event'];
          final isOrganizer = extra?['isOrganizer'] ?? false;

          return EventDetailScreen(
            eventId: eventId,
            isOrganizer: isOrganizer,
            eventDoc: event,
            joinLeaveService: EventActionService(),
          );
        },
      ),

      // Event Edit Route
      GoRoute(
        path: Routes.eventEdit,
        name: 'eventEdit',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final eventDoc = extra?['eventDoc'] as DocumentSnapshot?;

          // Get organizer ID from eventDoc instead of extra
          String organizer = '';
          if (eventDoc != null) {
            final data = eventDoc.data() as Map<String, dynamic>?;
            if (data != null) {
              organizer =
                  data['organizer'] ??
                  data['organizerId'] ??
                  data['createdBy'] ??
                  data['userId'] ??
                  data['creator'] ??
                  data['uid'] ??
                  '';
            }
          }

          return EventEditScreen(eventDoc: eventDoc!, organizer: organizer);
        },
      ),
    ],
  );
});
