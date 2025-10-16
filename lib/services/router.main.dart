part of 'router.dart';

// Auth state provider -- check user already logged or not
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// GoRouter provider
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      // final isAuthRoute = state.uri.path == Routes.login;
      final isAuthRoute =
          state.uri.path == Routes.login ||
          state.uri.path == Routes.register ||
          state.uri.path == Routes.role;
      final isSplash = state.uri.path == Routes.splash;

      // Allow splash screen
      if (isSplash) return null;

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isAuthRoute) return Routes.login;

      // Redirect to home if already authenticated and trying to access slogin
      if (isLoggedIn && isAuthRoute) return Routes.navigation;

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(isOrganizer: false),
      ),
      GoRoute(
        path: Routes.myEvents,
        name: 'myEvents',
        builder: (context, state) => const MyEventsContent(isOrganizer: null),
      ),
      GoRoute(
        path: Routes.addEvent,
        name: 'addEvent',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final organizerId = extra?['organizerId'] as String? ?? '';
          return AddEventScreen(organizer: organizerId);
        },
      ),
      GoRoute(
        path: '${Routes.eventDetail}/:id',
        name: 'eventDetail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final eventId = state.pathParameters['id'] ?? '';
          final event = extra?['event'];
          final isOrganizer = extra?['isOrganizer'] as bool? ?? false;

          return EventDetailScreen(
            eventId: eventId,
            isOrganizer: isOrganizer,
            eventDoc: event,
            joinLeaveService: EventActionService(),
          );
        },
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.navigation,
        name: 'navigation',
        builder: (context, state) {
          final user = FirebaseAuth.instance.currentUser;
          final userName = user?.displayName ?? '';
          return NavigationScreen(userName: userName);
        },
      ),
    ],
  );
});
