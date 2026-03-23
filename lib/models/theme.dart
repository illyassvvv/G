import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Dark ────────────────────────────────────────────────────
  static const Color darkBg       = Color(0xFF050A05);
  static const Color darkSurface  = Color(0xFF0D150D);
  static const Color darkSurface2 = Color(0xFF142014);
  static const Color darkCard     = Color(0xFF0F1A0F);
  static const Color darkText     = Color(0xFFF0F0F0);
  static const Color darkTextDim  = Color(0xFF7A8A7A);
  static const Color darkBorder   = Color(0x251DB954);

  // ─── Light ───────────────────────────────────────────────────
  static const Color lightBg       = Color(0xFFF4F4EF);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFECECE6);
  static const Color lightCard     = Color(0xFFFFFFFF);
  static const Color lightText     = Color(0xFF1A1A1A);
  static const Color lightTextDim  = Color(0xFF888888);
  static const Color lightBorder   = Color(0x301DB954);

  // ─── Shared ──────────────────────────────────────────────────
  static const Color accent    = Color(0xFF1DB954);
  static const Color accent2   = Color(0xFF4BDB7A);
  static const Color accentDim = Color(0xFF0D8F3E);
  static const Color green     = Color(0xFF1DB954);
  static const Color greenDim  = Color(0xFF0D5C2A);
  static const Color live      = Color(0xFFE63946);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [accent2, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [green, greenDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Material ThemeData ──────────────────────────────────────
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      ? AppTheme.accent.withOpacity(0.07)
      : AppTheme.accent.withOpacity(0.10);
  Color get appBarBg => isDark
      ? AppTheme.darkBg.withOpacity(0.94)
      : AppTheme.lightBg.withOpacity(0.94);
}
