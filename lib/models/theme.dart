import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Signature Gradient Colors ────────────────────────────────
  static const Color primary     = Color(0xFF22c55e);
  static const Color primaryDark = Color(0xFF16a34a);
  static const Color primaryDeep = Color(0xFF052e16);

  // ─── Dark Theme (True OLED Dark) ──────────────────────────────
  static const Color darkBg       = Color(0xFF0a0a0a);
  static const Color darkSurface  = Color(0xFF111111);
  static const Color darkSurface2 = Color(0xFF1a1a1a);
  static const Color darkCard     = Color(0xFF141414);
  static const Color darkText     = Color(0xFFF2F2F7);
  static const Color darkTextDim  = Color(0xFF737380);
  static const Color darkBorder   = Color(0x1AFFFFFF);

  // ─── Light Theme ──────────────────────────────────────────────
  static const Color lightBg       = Color(0xFFF7F7F7);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF0F0F0);
  static const Color lightCard     = Color(0xFFFFFFFF);
  static const Color lightText     = Color(0xFF18181B);
  static const Color lightTextDim  = Color(0xFF8C8C99);
  static const Color lightBorder   = Color(0x14000000);

  // ─── Accent & Status Colors ───────────────────────────────────
  static const Color accent    = Color(0xFF22c55e);
  static const Color accent2   = Color(0xFF4ade80);
  static const Color accentDim = Color(0xFF16a34a);
  static const Color live      = Color(0xFFFF3B5C);
  static const Color neonGlow  = Color(0xFF22c55e);

  // ─── Premium Gradients ────────────────────────────────────────
  static const LinearGradient signatureGradient = LinearGradient(
    colors: [Color(0xFF22c55e), Color(0xFF16a34a), Color(0xFF052e16)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF4ade80), Color(0xFF22c55e)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF22c55e), Color(0xFF16a34a)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradientDark = LinearGradient(
    colors: [Color(0xFF141414), Color(0xFF0a0a0a)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient surfaceGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F7F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Material ThemeData ──────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: primaryDark,
      surface: darkSurface,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: darkText,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkSurface2,
      contentTextStyle: GoogleFonts.inter(color: darkText),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: accent,
      secondary: primaryDark,
      surface: lightSurface,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: lightText,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightSurface2,
      contentTextStyle: GoogleFonts.inter(color: lightText),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

/// Theme-aware color resolver
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
      ? Colors.black.withOpacity(0.5)
      : Colors.black.withOpacity(0.08);
  Color get appBarBg => isDark
      ? AppTheme.darkBg.withOpacity(0.92)
      : AppTheme.lightBg.withOpacity(0.92);

  LinearGradient get surfaceGradient => isDark
      ? AppTheme.surfaceGradientDark
      : AppTheme.surfaceGradientLight;
}
