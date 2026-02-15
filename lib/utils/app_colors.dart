import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Matched to Vivah4Ever Logo)
  static const Color primaryBlue = Color(0xFF0E70B3); // Deep Blue from text
  static const Color primaryCyan = Color(0xFF2DC1D7); // Turquoise from logo
  static const Color background = Color(0xFFF0FBFF); // Light Sky Blue Glow
  
  // Complementary Colors
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF666666);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, primaryBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient verticalGradient = LinearGradient(
    colors: [primaryCyan, primaryBlue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
