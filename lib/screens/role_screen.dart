import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_buddy/services/routes.dart';
import 'package:event_buddy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:event_buddy/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum UserRole { user, organizer }

class UserRegistrationData {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? password;
  final String? dob;
  final bool fromGoogle;

  const UserRegistrationData({
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.dob,
    this.fromGoogle = false,
  });
}


class RegistrationState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const RegistrationState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  RegistrationState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) {
    return RegistrationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final currentUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

final registrationDataProvider = StateProvider<UserRegistrationData?>((ref) {
  return null;
});


class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final Ref ref;

  RegistrationNotifier(this.ref) : super(const RegistrationState());

  Future<User?> _registerUser(String email, String password) async {
    try {
      final auth = ref.read(firebaseAuthProvider);
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint('Registration failed: $e');
      rethrow;
    }
  }

  Future<String?> _getFcmToken() async {
    try {
      final authService = ref.read(authServiceProvider);
      return await authService.messaging.getToken();
    } catch (e) {
      debugPrint('FCM Token error: $e');
      return null;
    }
  }

  Future<void> _saveUserToFirestore(
    User user,
    UserRegistrationData regData,
    UserRole role,
  ) async {
    final firestore = ref.read(firestoreProvider);
    final fcmToken = await _getFcmToken();

    final userData = {
      "firstName": regData.firstName ?? "",
      "lastName": regData.lastName ?? "",
      "email": user.email ?? regData.email ?? "",
      "dob": regData.dob ?? "",
      "role": role == UserRole.organizer ? "organizer" : "user",
      "fcmToken": fcmToken,
      "isActive": true,
      "createdAt": FieldValue.serverTimestamp(),
    };

    debugPrint('Saving user data: $userData');

    final collection = role == UserRole.organizer ? "organizers" : "users";
    await firestore.collection(collection).doc(user.uid).set(userData);
  }

  Future<bool> registerWithRole(
    UserRegistrationData regData,
    UserRole role,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      User? user = ref.read(firebaseAuthProvider).currentUser;

      if (user == null && !regData.fromGoogle) {
        if (regData.email == null || regData.password == null) {
          throw Exception('Email and password required');
        }
        user = await _registerUser(regData.email!, regData.password!);
      }

      if (user == null) {
        throw Exception('User authentication failed');
      }

      await _saveUserToFirestore(user, regData, role);

      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const RegistrationState();
  }
}

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
      return RegistrationNotifier(ref);
    });


class RoleSelectionScreen extends ConsumerStatefulWidget {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? password;
  final String? dob;
  final bool fromGoogle;

  const RoleSelectionScreen({
    super.key,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.dob,
    this.fromGoogle = false,
  });

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrationDataProvider.notifier).state = UserRegistrationData(
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        password: widget.password,
        dob: widget.dob,
        fromGoogle: widget.fromGoogle,
      );
    });
  }

Future<void> _handleRoleSelection(UserRole role) async {
    final regData = ref.read(registrationDataProvider);
    if (regData == null) return;

    final notifier = ref.read(registrationProvider.notifier);
    final success = await notifier.registerWithRole(regData, role);

    if (!mounted) return;

    if (success) {
      final user = ref.read(firebaseAuthProvider).currentUser;
      final userName =
          widget.firstName ??
          user?.displayName ??
          user?.email?.split('@')[0] ??
          "User";

      context.go(
        Routes.navigation,
        extra: {
          'userName': userName,
          'isOrganizer': role == UserRole.organizer,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Successfully registered as ${role == UserRole.organizer ? 'organizer' : 'user'}!",
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationProvider);

    ref.listen<RegistrationState>(registrationProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        title: const Text("Choose Your Role"),
        centerTitle: true,
        backgroundColor: AppColors.card,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/images/role.svg', height: 200),
                const SizedBox(height: 20),
                const Text(
                  "Who would you like to join as?",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                _RoleButton(
                  label: "User",
                  onPressed: registrationState.isLoading
                      ? null
                      : () => _handleRoleSelection(UserRole.user),
                ),

                const SizedBox(height: 16),

                _RoleButton(
                  label: "Organizer",
                  onPressed: registrationState.isLoading
                      ? null
                      : () => _handleRoleSelection(UserRole.organizer),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Users can join events\nOrganizers can create and manage events",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          if (registrationState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}


class _RoleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _RoleButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
 