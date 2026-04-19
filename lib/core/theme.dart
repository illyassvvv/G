import 'package:flutter/material.dart';

class AppColors {
  // Dark mode
  static const background = Color(0xFF06070A);
  static const backgroundAlt = Color(0xFF0B1016);
  static const surface = Color(0xFF131A24);
  static const surfaceElevated = Color(0xFF1A2331);
  static const surfaceGlass = Color(0xCC141C28);
  static const primary = Color(0xFF6E8CFF);
  static const live = Color(0xFFFF4A3D);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9CA3AF);

  // Light mode equivalents
  static const backgroundLight = Color(0xFFF3F5F9);
  static const backgroundLightAlt = Color(0xFFECEFF5);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceLightAlt = Color(0xFFF8FAFD);
  static const textPrimaryLight = Color(0xFF0A0A0B);
  static const textSecondaryLight = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scaffold: AppColors.background,
        surface: AppColors.surface,
        elevatedSurface: AppColors.surfaceElevated,
        onSurface: AppColors.textPrimary,
        titleColor: Colors.white,
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scaffold: AppColors.backgroundLight,
        surface: AppColors.surfaceLight,
        elevatedSurface: AppColors.surfaceLightAlt,
        onSurface: AppColors.textPrimaryLight,
        titleColor: AppColors.textPrimaryLight,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color elevatedSurface,
    required Color onSurface,
    required Color titleColor,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      error: AppColors.live,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: elevatedSurface,
      onSurfaceVariant: onSurface.withOpacity(0.72),
      outline: brightness == Brightness.dark
          ? Colors.white.withOpacity(0.08)
          : const Color(0x1F000000),
      background: scaffold,
      onBackground: onSurface,
      surfaceTint: AppColors.primary.withOpacity(0.12),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      primaryColor: AppColors.primary,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: titleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: titleColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: titleColor),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: brightness == Brightness.dark
            ? Colors.white.withOpacity(0.08)
            : const Color(0x12000000),
        thickness: 1,
        space: 1,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: titleColor,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        titleMedium: TextStyle(
          color: titleColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        bodyMedium: TextStyle(color: onSurface),
      ),
    );
  }
}
