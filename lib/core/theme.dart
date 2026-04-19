import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Luxury-first design tokens.
/// Kept compact so the app stays lean while feeling premium.
class AppColors {
  // Dark / cinematic.
  static const background = Color(0xFF06070B);
  static const backgroundAlt = Color(0xFF0B0F16);
  static const surface = Color(0xFF101824);
  static const surfaceElevated = Color(0xFF182132);
  static const surfaceGlass = Color(0xD0141C2A);
  static const surfaceBorder = Color(0x14FFFFFF);

  // Accent system.
  static const primary = Color(0xFF96ABFF);
  static const primarySoft = Color(0xFF6D87FF);
  static const live = Color(0xFFFF5D58);
  static const success = Color(0xFF2ED07D);
  static const warning = Color(0xFFFFC857);

  // Text.
  static const textPrimary = Color(0xFFF6F8FF);
  static const textSecondary = Color(0xFFAAB1C2);

  // Light / warm ivory.
  static const backgroundLight = Color(0xFFF8F6F2);
  static const backgroundLightAlt = Color(0xFFEDE7DF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceLightAlt = Color(0xFFF7F4EF);
  static const surfaceLightBorder = Color(0x12000000);
  static const textPrimaryLight = Color(0xFF0B0D11);
  static const textSecondaryLight = Color(0xFF5D6677);
}

class AppTheme {
  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scaffold: AppColors.background,
        surface: AppColors.surface,
        elevatedSurface: AppColors.surfaceElevated,
        onSurface: AppColors.textPrimary,
        titleColor: AppColors.textPrimary,
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
    final isDark = brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : AppColors.surfaceLightBorder;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primarySoft,
      onSecondary: Colors.white,
      tertiary: isDark ? AppColors.success : const Color(0xFF159B56),
      onTertiary: Colors.white,
      error: AppColors.live,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceVariant: elevatedSurface,
      onSurfaceVariant: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
      outline: borderColor,
      outlineVariant: isDark ? Colors.white.withOpacity(0.05) : const Color(0x0C000000),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? Colors.white : Colors.black,
      onInverseSurface: isDark ? Colors.black : Colors.white,
      background: scaffold,
      onBackground: onSurface,
    );

    final base = Typography.material2021(platform: TargetPlatform.iOS)
        .black
        .apply(bodyColor: onSurface, displayColor: onSurface);

    final textTheme = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 54,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        height: 1.06,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
        height: 1.06,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.85,
        height: 1.08,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        height: 1.08,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        height: 1.12,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.15,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.18,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05,
        height: 1.2,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.42),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.34),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.24,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      primaryColor: AppColors.primary,
      colorScheme: scheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: titleColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        iconTheme: IconThemeData(color: titleColor, size: 22),
        titleTextStyle: TextStyle(
          color: titleColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.45,
          height: 1.1,
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: borderColor),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0x10000000),
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        size: 22,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 22,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: isDark ? Colors.white.withOpacity(0.10) : const Color(0x12000000),
        circularTrackColor: isDark ? Colors.white.withOpacity(0.10) : const Color(0x12000000),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevatedSurface,
        contentTextStyle: TextStyle(
          color: titleColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: TextStyle(
          color: titleColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.35,
        ),
        contentTextStyle: TextStyle(
          color: onSurface.withOpacity(0.82),
          fontSize: 14,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withOpacity(isDark ? 0.84 : 0.94),
        indicatorColor: AppColors.primary.withOpacity(isDark ? 0.18 : 0.11),
        elevation: 0,
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return TextStyle(
            color: selected ? AppColors.primary : scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          );
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : scheme.onSurfaceVariant,
            size: 22,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: elevatedSurface,
          foregroundColor: titleColor,
          shadowColor: Colors.black.withOpacity(0.22),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: borderColor),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: titleColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevatedSurface.withOpacity(isDark ? 0.84 : 0.96),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.82), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.live, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.live, width: 1.4),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return isDark ? Colors.white.withOpacity(0.78) : Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          return scheme.onSurfaceVariant.withOpacity(0.22);
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((_) => Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          return scheme.onSurfaceVariant.withOpacity(0.20);
        }),
        side: BorderSide(color: scheme.onSurfaceVariant.withOpacity(0.35)),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          return scheme.onSurfaceVariant.withOpacity(0.5);
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: scheme.onSurfaceVariant,
        textColor: titleColor,
        tileColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      splashColor: AppColors.primary.withOpacity(0.10),
      highlightColor: AppColors.primary.withOpacity(0.06),
      hoverColor: AppColors.primary.withOpacity(0.05),
      focusColor: AppColors.primary.withOpacity(0.08),
    );
  }
}
