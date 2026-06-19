import 'package:flutter/material.dart';

class AppThemeConfig {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color darkPrimary;
  final Color darkSecondary;

  AppThemeConfig({
    this.primaryColor = const Color(0xFF00C897),
    this.secondaryColor = const Color(0xFF00A87D),
    this.backgroundColor = const Color(0xFFF5FBF9),
    this.surfaceColor = Colors.white,
    this.textColor = const Color(0xFF212121),
    this.gradientStart = const Color(0xFF00C897),
    this.gradientEnd = const Color(0xFF00A87D),
    this.darkPrimary = const Color(0xFF42A5F5),
    this.darkSecondary = const Color(0xFF64B5F6),
  });

  factory AppThemeConfig.fromJson(Map<String, dynamic> json) {
    return AppThemeConfig(
      primaryColor: _parseColor(json['primary_color'], 0xFF00C897),
      secondaryColor: _parseColor(json['secondary_color'], 0xFF00A87D),
      backgroundColor: _parseColor(json['background_color'], 0xFFF5FBF9),
      surfaceColor: _parseColor(json['surface_color'], 0xFFFFFFFF),
      textColor: _parseColor(json['text_color'], 0xFF212121),
      gradientStart: _parseColor(json['gradient_start'], 0xFF00C897),
      gradientEnd: _parseColor(json['gradient_end'], 0xFF00A87D),
      darkPrimary: _parseColor(json['dark_primary'], 0xFF42A5F5),
      darkSecondary: _parseColor(json['dark_secondary'], 0xFF64B5F6),
    );
  }

  static Color _parseColor(String? hex, int defaultHex) {
    if (hex == null || hex.isEmpty) return Color(defaultHex);
    final h = hex.replaceFirst('#', '');
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    return Color(defaultHex);
  }

  LinearGradient get primaryGradient => LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  LinearGradient get verticalGradient => LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
