import 'package:flutter/material.dart';
import '../services/theme_config_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Color get lightPrimary => ThemeConfigService.instance.config.primaryColor;
  Color get lightSecondary => ThemeConfigService.instance.config.secondaryColor;
  Color get lightBackground => ThemeConfigService.instance.config.backgroundColor;
  Color get lightSurface => ThemeConfigService.instance.config.surfaceColor;
  Color get lightText => ThemeConfigService.instance.config.textColor;
  Color get darkPrimary => ThemeConfigService.instance.config.darkPrimary;
  Color get darkSecondary => ThemeConfigService.instance.config.darkSecondary;

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
    final primary = lightPrimary;
    final secondary = lightSecondary;
    final background = lightBackground;
    final surface = lightSurface;
    final dPrimary = darkPrimary;
    final dSecondary = darkSecondary;

    if (_isDarkMode) {
      return ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: dPrimary,
          brightness: Brightness.dark,
          primary: dPrimary,
          secondary: dSecondary,
        ),
        useMaterial3: true,
        textTheme: _textTheme,
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          primary: primary,
          secondary: secondary,
          surface: surface,
        ),
        useMaterial3: true,
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          prefixIconColor: primary,
          suffixIconColor: primary,
          errorStyle: TextStyle(color: primary, fontWeight: FontWeight.bold),
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
            borderSide: BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primary, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: primary, width: 2),
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
