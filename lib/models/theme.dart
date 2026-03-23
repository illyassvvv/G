import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark base
  static const Color bg        = Color(0xFF050A05);
  static const Color surface   = Color(0xFF0D150D);
  static const Color surface2  = Color(0xFF142014);
  static const Color card      = Color(0xFF0F1A0F);

  // Gold accent
  static const Color accent    = Color(0xFFD4AF37);
  static const Color accent2   = Color(0xFFE8C96B);
  static const Color accentDim = Color(0xFF8B7014);

  // Green accent
  static const Color green     = Color(0xFF1DB954);
  static const Color greenDim  = Color(0xFF0D5C2A);
  static const Color greenGlow = Color(0xFF15803D);

  // Status
  static const Color live      = Color(0xFFE63946);

  // Text
  static const Color text      = Color(0xFFF0F0F0);
  static const Color textDim   = Color(0xFF7A8A7A);

  // Border
  static const Color border    = Color(0x25D4AF37);

  // Gradient
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

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: green,
      surface: surface,
    ),
    textTheme: GoogleFonts.cairoTextTheme(
      ThemeData.dark().textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: text,
      ),
    ),
  );
}
