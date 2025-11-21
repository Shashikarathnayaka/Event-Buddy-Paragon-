import 'package:event_buddy/services/prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:event_buddy/services/auth_service.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService;
  final PreferencesService _preferencesService = PreferencesService();

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

      // ignore: unnecessary_null_comparison
      if (result != null) {
        await _preferencesService.saveUserData(
          role: result['role'] ?? '',
          firstName: result['firstName'] ?? '',
          userId: result['userId'] ?? '',
          email: result['email'] ?? '',
        );
      }

      return result;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> signInWithGoogle(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signInWithGoogle(context);

      final result = _preferencesService.getUserData();

      return result;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? getSavedUserData() {
    return _preferencesService.getUserData();
  }

  Future<void> logout() async {
    await _preferencesService.clearUserData();
    notifyListeners();
  }

  bool isUserLoggedIn() {
    return _preferencesService.isUserLoggedIn();
  }
}
