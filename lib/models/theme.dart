import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Dark Mode ────────────────────────────────────────────
  static const Color darkBg       = Color(0xFF050A05);
  static const Color darkSurface  = Color(0xFF0D150D);
  static const Color darkSurface2 = Color(0xFF142014);
  static const Color darkCard     = Color(0xFF0F1A0F);

  // ── Light Mode ───────────────────────────────────────────
  static const Color lightBg       = Color(0xFFF5F5F0);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEEEEE8);
  static const Color lightCard     = Color(0xFFFFFFFF);

  // ── Shared ───────────────────────────────────────────────
  static const Color accent    = Color(0xFFD4AF37);
  static const Color accent2   = Color(0xFFE8C96B);
  static const Color accentDim = Color(0xFF8B7014);
  static const Color green     = Color(0xFF1DB954);
  static const Color greenDim  = Color(0xFF0D5C2A);
  static const Color live      = Color(0xFFE63946);

  // ── Gradients ────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [accent, accentDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [green, greenDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Theme builders ───────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: green,
      surface: darkSurface,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 20, fontWeight: FontWeight.w900,
        color: const Color(0xFFF0F0F0),
      ),
    ),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: accent,
      secondary: green,
      surface: lightSurface,
    ),
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 20, fontWeight: FontWeight.w900,
        color: const Color(0xFF1A1A1A),
      ),
    ),
  );
}

// ── Theme-aware color helpers ────────────────────────────────
class ThemeColors {
  final bool isDark;
  const ThemeColors(this.isDark);

  Color get bg       => isDark ? AppTheme.darkBg       : AppTheme.lightBg;
  Color get surface  => isDark ? AppTheme.darkSurface  : AppTheme.lightSurface;
  Color get surface2 => isDark ? AppTheme.darkSurface2 : AppTheme.lightSurface2;
  Color get card     => isDark ? AppTheme.darkCard     : AppTheme.lightCard;
  Color get text     => isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
  Color get textDim  => isDark ? const Color(0xFF7A8A7A) : const Color(0xFF888888);
  Color get border   => isDark ? const Color(0x25D4AF37) : const Color(0x30D4AF37);
  Color get cardShadow => isDark
      ? AppTheme.accent.withOpacity(0.08)
      : AppTheme.accent.withOpacity(0.12);
}
