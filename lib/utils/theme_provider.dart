import 'package:flutter/material.dart';
import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Light Mode Colors (Matched to Nikkah Match Logo)
  static const Color lightPrimary = AppColors.primaryBlue;
  static const Color lightSecondary = AppColors.primaryCyan;
  static const Color lightBackground = AppColors.background;
  static const Color lightAccent = AppColors.primaryCyan;

  // Dark Mode Colors
  static const Color darkPrimary = Color(0xFF42A5F5); 
  static const Color darkSecondary = Color(0xFF64B5F6); 
  static const Color darkAccent = Color(0xFFBA68C8); 


  static const _textTheme = TextTheme(
    displayLarge: TextStyle(fontWeight: FontWeight.w400),
    displayMedium: TextStyle(fontWeight: FontWeight.w400),
    displaySmall: TextStyle(fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontWeight: FontWeight.w400),
    headlineSmall: TextStyle(fontWeight: FontWeight.w400),
    titleLarge: TextStyle(fontWeight: FontWeight.w400),
    titleMedium: TextStyle(fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontWeight: FontWeight.w500),
  );

  ThemeData get themeData {
    if (_isDarkMode) {
      return ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkPrimary,
          brightness: Brightness.dark,
          primary: darkPrimary,
          secondary: darkSecondary,
        ),
        useMaterial3: true,
        textTheme: _textTheme,
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: lightPrimary,
          brightness: Brightness.light,
          primary: lightPrimary,
          secondary: lightSecondary,
          surface: Colors.white,
        ),
        useMaterial3: true,
        textTheme: _textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          prefixIconColor: lightPrimary,
          suffixIconColor: lightPrimary,
          errorStyle: const TextStyle(color: lightPrimary, fontWeight: FontWeight.bold),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: lightPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: lightPrimary, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: lightPrimary, width: 2),
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