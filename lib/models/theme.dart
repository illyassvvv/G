import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Dark ────────────────────────────────────────────────────
  static const Color darkBg       = Color(0xFF0D1117);
  static const Color darkSurface  = Color(0xFF161B22);
  static const Color darkSurface2 = Color(0xFF21262D);
  static const Color darkCard     = Color(0xFF161B22);
  static const Color darkText     = Color(0xFFF0F6FC);
  static const Color darkTextDim  = Color(0xFF8B949E);
  static const Color darkBorder   = Color(0xFF30363D);

  // ─── Light ───────────────────────────────────────────────────
  static const Color lightBg       = Color(0xFFF6F8FA);
  static const Color lightSurface  = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFEFF2F5);
  static const Color lightCard     = Color(0xFFFFFFFF);
  static const Color lightText     = Color(0xFF1F2328);
  static const Color lightTextDim  = Color(0xFF656D76);
  static const Color lightBorder   = Color(0xFFD0D7DE);

  // ─── Shared accent = green ─────────────────────────────────
  static const Color accent    = Color(0xFF00E676);
  static const Color accent2   = Color(0xFF69F0AE);
  static const Color accentDim = Color(0xFF00C853);
  static const Color green     = Color(0xFF00E676);
  static const Color greenDim  = Color(0xFF00894A);
  static const Color live      = Color(0xFFFF1744);

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentDim],
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
      primary: accent, secondary: accent2, surface: darkSurface,
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
      primary: accent, secondary: accent2, surface: lightSurface,
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
      ? Colors.black.withOpacity(0.35)
      : Colors.black.withOpacity(0.08);
  Color get appBarBg => isDark
      ? AppTheme.darkBg.withOpacity(0.96)
      : AppTheme.lightBg.withOpacity(0.96);
}
