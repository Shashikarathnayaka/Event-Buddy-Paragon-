// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ThemeProvider extends ChangeNotifier {
//   static const String _prefKey = "theme_mode"; // "light", "dark", "system"

//   ThemeMode _themeMode = ThemeMode.system;
//   ThemeMode get themeMode => _themeMode;

//   ThemeProvider() {
//     _loadFromPrefs();
//   }

//   void setThemeMode(ThemeMode mode) {
//     _themeMode = mode;
//     _saveToPrefs(mode);
//     notifyListeners();
//   }

//   bool get isDarkMode {
//     if (_themeMode == ThemeMode.system) {
//       // system dependent, but we cannot get platform brightness here.
//       return false;
//     }
//     return _themeMode == ThemeMode.dark;
//   }

//   Future<void> _loadFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     final value = prefs.getString(_prefKey) ?? "system";
//     switch (value) {
//       case "light":
//         _themeMode = ThemeMode.light;
//         break;
//       case "dark":
//         _themeMode = ThemeMode.dark;
//         break;
//       default:
//         _themeMode = ThemeMode.system;
//     }
//     notifyListeners();
//   }

//   Future<void> _saveToPrefs(ThemeMode mode) async {
//     final prefs = await SharedPreferences.getInstance();
//     String value = "system";
//     if (mode == ThemeMode.light) value = "light";
//     if (mode == ThemeMode.dark) value = "dark";
//     await prefs.setString(_prefKey, value);
//   }
// }
