import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Dynamic)
  static Color primaryGreen = const Color(0xFF00C897);
  static Color deepGreen = const Color(0xFF00A87D);
  static Color darkGreen = const Color(0xFF00875F);
  static Color mintTint = const Color(0xFFD4F5EB);
  static Color softMint = const Color(0xFFE8FBF5);
  
  // Neutrals
  static const Color white = Colors.white;
  static const Color offWhite = Color(0xFFF5FBF9);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color mutedText = Color(0xFF9E9E9E);
  static const Color bodyText = Color(0xFF212121);

  // Legacy/Compatibility Mapping (Updating to match new theme)
  static Color get primaryBlue => primaryGreen;
  static Color get primaryCyan => deepGreen;
  static const Color background = offWhite;
  
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF666666);
  
  // Gradients (Updated for Green Theme)
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryGreen, deepGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient get verticalGradient => LinearGradient(
    colors: [primaryGreen, deepGreen],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- Legacy Theme Colors Mapped to Current Theme ---
  static Color get midnightEmerald => darkGreen;
  static Color get deepEmerald => primaryGreen;
  static const Color cardDark = Color(0xFFFFFFFF); // Cards are white in new theme
  static const Color textDark = bodyText;
  static const Color backgroundLight = offWhite;
  static const Color creamGold = Color(0xFFFEF3C7);
  static const Color royalGold = Color(0xFFF59E0B);
}
