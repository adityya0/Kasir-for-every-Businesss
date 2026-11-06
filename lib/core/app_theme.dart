import 'package:flutter/material.dart';

class AppTheme {
  // OMNI POS - Vibrant Green Theme
  static const Color primaryColor = Color(0xFF00BF63);      // Vibrant Green (Brand Logo)
  static const Color primaryLight = Color(0xFF2EE589);      // Bright Leaf Green
  static const Color primaryDark = Color(0xFF0D7A4E);       // Deep Forest Green
  static const Color secondaryColor = Color(0xFF10B981);    // Emerald accent
  static const Color backgroundColor = Color(0xFFF8F9FD);   // Clean crisp background
  static const Color surfaceColor = Colors.white;

  // Harmonized Financial & Status Colors (Smooth Hijau & Merah Muda)
  static const Color incomeGreen = Color(0xFF0D8A50);       // Smooth Forest Green for income/positive
  static const Color incomeGreenLight = Color(0xFFECFDF5);  // Soft pastel green background
  static const Color incomeGreenBorder = Color(0xFFA7F3D0); // Delicate green border
  static const Color incomeGreenText = Color(0xFF065F46);   // Deep readable green text

  static const Color expenseRose = Color(0xFFE05260);        // Smooth elegant Merah Muda / Soft Rose
  static const Color expenseRoseLight = Color(0xFFFFF1F2);   // Soft pastel rose background
  static const Color expenseRoseBorder = Color(0xFFFECDD3);  // Delicate rose border
  static const Color expenseRoseText = Color(0xFFBE123C);    // Deep readable rose text
  static const Color expenseRoseDark = Color(0xFF9F1239);    // Contrast dark rose

  static const Gradient defaultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00BF63),  // Vibrant Green
      Color(0xFF10B981),  // Emerald Green
    ],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
}
