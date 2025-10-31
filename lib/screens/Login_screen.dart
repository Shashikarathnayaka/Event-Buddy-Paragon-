import 'package:event_buddy/services/auth_service.dart';
import 'package:event_buddy/services/routes.dart';
import 'package:event_buddy/theme/app_colors.dart';
import 'package:event_buddy/utils/core_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class LoginController extends ChangeNotifier {
  final AuthService _authService;

  LoginController(this._authService);

  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> loginWithEmail(
    String email,
    String password,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.loginWithEmail(email, password);
      return result;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signInWithGoogle(context);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

final loginControllerProvider = ChangeNotifierProvider<LoginController>((ref) {
  return LoginController(ref.watch(authServiceProvider));
});

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final result = await ref
          .read(loginControllerProvider)
          .loginWithEmail(_emailController.text, _passwordController.text);

      if (!mounted) return;

      if (result != null) {
        _navigateHome(result["role"], result["firstName"]);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;

    try {
      await ref.read(loginControllerProvider).signInWithGoogle(context);
    } catch (e) {
      CoreUtils.toastError("Google Sign-In failed: $e");
    }
  }

  void _navigateHome(String role, String firstName) {
    final isOrganizer = role == "Organizer";

    context.go(
      Routes.navigation,
      extra: {'userName': firstName, 'isOrganizer': isOrganizer},
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      hintText: hint,
      filled: true,
      fillColor: const Color.fromARGB(255, 12, 12, 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color.fromARGB(255, 53, 137, 158)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(loginControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SvgPicture.asset(
                    'assets/images/signin.svg',
                    height: 250,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please Sign in to continue.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 206, 200, 200),
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration("Email", Icons.person_outline),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your email'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: controller.obscurePassword,
                  decoration: _inputDecoration("Password", Icons.lock_outline)
                      .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            controller.togglePasswordVisibility();
                          },
                        ),
                      ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your password'
                      : null,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 53, 137, 158),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.maxFinite, 48),
                  ),
                  onPressed: controller.isLoading ? null : _loginUser,
                  child: controller.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SIGN IN"),
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 24, 23, 23),
                    foregroundColor: const Color.fromARGB(255, 240, 238, 238),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    minimumSize: const Size(double.maxFinite, 48),
                  ),
                  icon: SvgPicture.asset(
                    'assets/images/google icon.svg',
                    height: 24,
                  ),
                  label: const Text("Sign in with Google"),
                  onPressed: controller.isLoading ? null : _signInWithGoogle,
                ),
                const SizedBox(height: 16),
                // Center(
                //   child: GestureDetector(
                //     onTap: () {
                //       context.push(
                //         Routes.register,
                //       ); // Changed from context.go()
                //     },
                //     child: Text.rich(
                //       TextSpan(
                //         text: "Don't have account? ",
                //         style: TextStyle(color: Colors.grey),
                //         children: [
                //           TextSpan(
                //             text: "Sign Up",
                //             style: TextStyle(
                //               color: Colors.blue,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have account? ",
                      style: const TextStyle(
                        color: Color.fromARGB(255, 192, 183, 183),
                      ),
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style: const TextStyle(
                            color: Color.fromARGB(255, 65, 126, 231),
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              context.go(Routes.register);
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
