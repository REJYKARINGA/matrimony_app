import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Islamic Matrimonial Theme - Green Palette)
  static const Color primaryGreen = Color(0xFF00C897);
  static const Color deepGreen = Color(0xFF00A87D);
  static const Color darkGreen = Color(0xFF00875F);
  static const Color mintTint = Color(0xFFD4F5EB);
  static const Color softMint = Color(0xFFE8FBF5);
  
  // Neutrals
  static const Color white = Colors.white;
  static const Color offWhite = Color(0xFFF5FBF9);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color mutedText = Color(0xFF9E9E9E);
  static const Color bodyText = Color(0xFF212121);

  // Legacy/Compatibility Mapping (Updating to match new theme)
  static const Color primaryBlue = Color(0xFF00C897); // Mapping to primaryGreen
  static const Color primaryCyan = Color(0xFF00A87D); // Mapping to deepGreen
  static const Color background = offWhite;
  
  static const Color lightGrey = Color(0xFFEEEEEE);
  static const Color darkGrey = Color(0xFF666666);
  
  // Gradients (Updated for Green Theme)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, deepGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient verticalGradient = LinearGradient(
    colors: [primaryGreen, deepGreen],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- Legacy Theme Colors Mapped to Current Theme ---
  static const Color midnightEmerald = darkGreen;
  static const Color deepEmerald = primaryGreen;
  static const Color cardDark = Color(0xFFFFFFFF); // Cards are white in new theme
  static const Color textDark = bodyText;
  static const Color backgroundLight = offWhite;
  static const Color creamGold = Color(0xFFFEF3C7);
  static const Color royalGold = Color(0xFFF59E0B);
}
