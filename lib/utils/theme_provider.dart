import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Light Mode Colors
  static const Color lightPrimary = Color(0xFFE91E63); // Rose Pink
  static const Color lightSecondary = Color(0xFF1976D2); // Deep Blue
  static const Color lightAccent = Color(0xFFFFB300); // Gold

  // Dark Mode Colors
  static const Color darkPrimary = Color(0xFFF06292); // Light Pink
  static const Color darkSecondary = Color(0xFF42A5F5); // Light Blue
  static const Color darkAccent = Color(0xFFFFD54F); // Light Gold

  ThemeData get themeData {
    if (_isDarkMode) {
      return ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkPrimary,
          brightness: Brightness.dark,
          primary: darkPrimary,
          secondary: darkSecondary,
          tertiary: darkAccent,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkPrimary,
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lightPrimary,
          brightness: Brightness.light,
          primary: lightPrimary,
          secondary: lightSecondary,
          tertiary: lightAccent,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightPrimary,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}