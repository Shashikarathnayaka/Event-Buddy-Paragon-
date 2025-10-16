part of 'router.dart';

 final authStateProvider = StreamProvider<User?>((ref) {
   return FirebaseAuth.instance.authStateChanges();
 });

 final goRouterProvider = Provider<GoRouter>((ref) {
   final authState = ref.watch(authStateProvider);

   return GoRouter(
     initialLocation: '/splash',

     redirect: (context, state) {
       final isLoggedIn = authState.value != null;
       final isAuthRoute = state.uri.path == '/auth';
       final isSplash = state.uri.path == '/splash';

       if (isSplash) return null;
       if (!isLoggedIn && !isAuthRoute) return '/auth';
       if (isLoggedIn && isAuthRoute) return '/home';

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
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(isOrganizer: false),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.myEvents,
        name: 'myEvents',
        builder: (context, state) => const MyEventsContent(isOrganizer: null,),
      ),
      GoRoute(
        path: Routes.addEvent,
        name: 'addEvent',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final organizerId = extra['organizerId'] as String? ?? '';
          return AddEventScreen(organizer: organizerId);
        },
      ),
       GoRoute(
        path: '/EventDetailScreen/:id',
        name: 'eventDetail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final event = extra['event'];
          final isOrganizer = extra['isOrganizer'] ?? false;
          final eventId = state.pathParameters['id'] ?? '';

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
