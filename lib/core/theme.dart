import 'package:flutter/material.dart';

class AppColors {
  // Dark mode
  static const background    = Color(0xFF0B0B0C);
  static const surface       = Color(0xFF1A1A1C);
  static const surfaceElevated = Color(0xFF232325);
  static const primary       = Color(0xFF0A84FF);
  static const live          = Color(0xFFFF3B30);
  static const textPrimary   = Colors.white;
  static const textSecondary = Color(0xFF9A9A9E);

  // Light mode equivalents (resolved by AppTheme helpers)
  static const backgroundLight    = Color(0xFFF2F2F7);
  static const surfaceLight       = Color(0xFFFFFFFF);
  static const textPrimaryLight   = Color(0xFF0A0A0A);
  static const textSecondaryLight = Color(0xFF6C6C70);
}

class AppTheme {
  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scaffold: AppColors.background,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    titleColor: Colors.white,
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    scaffold: AppColors.backgroundLight,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    titleColor: AppColors.textPrimaryLight,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color onSurface,
    required Color titleColor,
  }) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primary,
        onSecondary: Colors.white,
        error: AppColors.live,
        onError: Colors.white,
        background: scaffold,
        onBackground: onSurface,
        surface: surface,
        onSurface: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: titleColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: titleColor),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: onSurface),
      ),
    );
  }
}
