import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  late SharedPreferences _prefs;

  PreferencesService._internal();

  factory PreferencesService() {
    return _instance;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User Login Data
  Future<bool> saveUserData({
    required String role,
    required String firstName,
    required String userId,
    required String email,
  }) async {
    try {
      await _prefs.setString('userRole', role);
      await _prefs.setString('firstName', firstName);
      await _prefs.setString('userId', userId);
      await _prefs.setString('userEmail', email);
      await _prefs.setBool('isLoggedIn', true);
      await _prefs.setString('loginTime', DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  Map<String, dynamic>? getUserData() {
    try {
      final isLoggedIn = _prefs.getBool('isLoggedIn') ?? false;
      if (!isLoggedIn) return null;

      return {
        'role': _prefs.getString('userRole'),
        'firstName': _prefs.getString('firstName'),
        'userId': _prefs.getString('userId'),
        'email': _prefs.getString('userEmail'),
      };
    } catch (e) {
      print('Error retrieving user data: $e');
      return null;
    }
  }

  String? getUserRole() => _prefs.getString('userRole');
  String? getFirstName() => _prefs.getString('firstName');
  String? getUserId() => _prefs.getString('userId');
  String? getUserEmail() => _prefs.getString('userEmail');
  bool isUserLoggedIn() => _prefs.getBool('isLoggedIn') ?? false;

  Future<bool> clearUserData() async {
    try {
      await _prefs.remove('userRole');
      await _prefs.remove('firstName');
      await _prefs.remove('userId');
      await _prefs.remove('userEmail');
      await _prefs.remove('loginTime');
      await _prefs.setBool('isLoggedIn', false);
      return true;
    } catch (e) {
      print('Error clearing user data: $e');
      return false;
    }
  }

  // Remember Email
  Future<bool> saveRememberEmail(String email) async {
    return await _prefs.setString('rememberEmail', email);
  }

  String? getRememberEmail() => _prefs.getString('rememberEmail');

  Future<bool> clearRememberEmail() async {
    return await _prefs.remove('rememberEmail');
  }
}
