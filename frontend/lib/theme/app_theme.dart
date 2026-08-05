import 'package:flutter/material.dart';

class AppTheme {
  // MLS/Premier League inspired colors - clean and modern
  static const Color primaryPurple = Color(0xFF6366F1); // Vibrant purple
  static const Color primaryGreen = Color(0xFF10B981); // Success green
  static const Color backgroundLight = Color(0xFFF8FAFC); // Off-white
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A); // Almost black
  static const Color textSecondary = Color(0xFF64748B); // Gray
  static const Color accent = Color(0xFFEC4899); // Pink accent
  static const Color liveRed = Color(0xFFEF4444);

  // Team colors - bright and distinct
  static const Color kmGold = Color(0xFFFBBF24); // Bright gold for KM
  static const Color reserveBlue = Color(0xFF3B82F6); // Bright blue
  static const Color womenPink = Color(0xFFEC4899); // Hot pink

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryPurple,
        secondary: primaryGreen,
        surface: cardWhite,
        error: liveRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryPurple, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
