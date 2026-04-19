import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0B0B0C);
  static const surface = Color(0xFF1A1A1C);
  static const surfaceElevated = Color(0xFF232325);
  static const primary = Color(0xFF0A84FF);
  static const live = Color(0xFFFF3B30);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9A9A9E);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
