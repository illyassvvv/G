import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Dark (Cinematic OLED) ──────────────────────────────────
  static const Color darkBg       = Color(0xFF000000);
  static const Color darkSurface  = Color(0xFF0D0D12);
  static const Color darkSurface2 = Color(0xFF16161F);
  static const Color darkCard     = Color(0xFF111118);
  static const Color darkText     = Color(0xFFF2F2F7);
  static const Color darkTextDim  = Color(0xFF6E6E80);
  static const Color darkBorder   = Color(0x1AFFFFFF);

  // ─── Light (Soft & Elegant) ─────────────────────────────────
  static const Color lightBg       = Color(0xFFF6F5F1);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEEEDE8);
  static const Color lightCard     = Color(0xFFFFFFFF);
  static const Color lightText     = Color(0xFF18181B);
  static const Color lightTextDim  = Color(0xFF8C8C99);
  static const Color lightBorder   = Color(0x14000000);

  // ─── Accent Palette ─────────────────────────────────────────
  static const Color accent    = Color(0xFF00E59B);
  static const Color accent2   = Color(0xFF00FFC6);
  static const Color accentDim = Color(0xFF00B377);
  static const Color green     = Color(0xFF00E59B);
  static const Color greenDim  = Color(0xFF007A52);
  static const Color live      = Color(0xFFFF3B5C);

  // ─── Premium Gradients ──────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFF00FFC6), Color(0xFF00E59B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00E59B), Color(0xFF007A52)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGlow = LinearGradient(
    colors: [Color(0xFF00FFC6), Color(0xFF00E59B), Color(0xFF00B377)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient surfaceGradientDark = LinearGradient(
    colors: [Color(0xFF111118), Color(0xFF0D0D12)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient surfaceGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F8F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Material ThemeData ────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: accent, secondary: green, surface: darkSurface,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0,
      titleTextStyle: GoogleFonts.cairo(
          fontSize: 20, fontWeight: FontWeight.w900, color: darkText),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkSurface2,
      contentTextStyle: GoogleFonts.cairo(color: darkText),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: accent, secondary: green, surface: lightSurface,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0,
      titleTextStyle: GoogleFonts.cairo(
          fontSize: 20, fontWeight: FontWeight.w900, color: lightText),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightSurface2,
      contentTextStyle: GoogleFonts.cairo(color: lightText),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

/// Theme-aware color resolver — pass isDark from AppProvider
class TC {
  final bool isDark;
  const TC(this.isDark);

  Color get bg       => isDark ? AppTheme.darkBg       : AppTheme.lightBg;
  Color get surface  => isDark ? AppTheme.darkSurface  : AppTheme.lightSurface;
  Color get surface2 => isDark ? AppTheme.darkSurface2 : AppTheme.lightSurface2;
  Color get card     => isDark ? AppTheme.darkCard     : AppTheme.lightCard;
  Color get text     => isDark ? AppTheme.darkText     : AppTheme.lightText;
  Color get textDim  => isDark ? AppTheme.darkTextDim  : AppTheme.lightTextDim;
  Color get border   => isDark ? AppTheme.darkBorder   : AppTheme.lightBorder;
  Color get shadow   => isDark
      ? Colors.black.withOpacity(0.4)
      : Colors.black.withOpacity(0.06);
  Color get appBarBg => isDark
      ? AppTheme.darkBg.withOpacity(0.85)
      : AppTheme.lightBg.withOpacity(0.88);

  LinearGradient get surfaceGradient => isDark
      ? AppTheme.surfaceGradientDark
      : AppTheme.surfaceGradientLight;
}
