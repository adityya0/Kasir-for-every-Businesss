import 'package:flutter/material.dart';

class AppTheme {
  // Warkop Alam POS - Vibrant Orange Theme (Original & Modern)
  static const Color primaryColor = Color(0xFFEA5700);      // Vibrant Orange
  static const Color primaryLight = Color(0xFFFF8E53);      // Warm Coral Orange
  static const Color primaryDark = Color(0xFFC0392B);       // Deep Amber/Rust
  static const Color secondaryColor = Color(0xFFFF9F43);    // Warm amber accent
  static const Color backgroundColor = Color(0xFFF8F9FD);   // Clean crisp background
  static const Color surfaceColor = Colors.white;

  static const Gradient defaultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEA5700),  // Vibrant Orange
      Color(0xFFFF8E53),  // Coral Orange
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
}
