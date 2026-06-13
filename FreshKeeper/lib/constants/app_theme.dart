import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF0E6E20);
  static const Color surfaceBackground = Color(0xFFF8F9FA);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: surfaceBackground,
      colorScheme: const ColorScheme.light(primary: primaryGreen),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryGreen, width: 2),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }
}