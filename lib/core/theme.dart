import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Dark palette: rich charcoal with restrained neon.
  static const background = Color(0xFF05070B);
  static const backgroundAlt = Color(0xFF0A1018);
  static const surface = Color(0xFF101722);
  static const surfaceElevated = Color(0xFF182133);
  static const surfaceGlass = Color(0xD0121824);
  static const surfaceBorder = Color(0x14FFFFFF);

  static const primary = Color(0xFF9DB2FF);
  static const primarySoft = Color(0xFF6886FF);
  static const live = Color(0xFFFF5D58);
  static const success = Color(0xFF2ED07D);
  static const warning = Color(0xFFFFC857);

  static const textPrimary = Color(0xFFF6F8FF);
  static const textSecondary = Color(0xFFABB1C0);

  // Light palette: warm ivory with gentle contrast.
  static const backgroundLight = Color(0xFFF7F5F2);
  static const backgroundLightAlt = Color(0xFFECE7E1);
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

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: isDark ? AppColors.primarySoft : AppColors.primarySoft,
      onSecondary: Colors.white,
      tertiary: isDark ? AppColors.success : const Color(0xFF12A150),
      error: AppColors.live,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceTintColor: AppColors.primary.withOpacity(isDark ? 0.16 : 0.08),
      surfaceContainerLowest: scaffold,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: elevatedSurface,
      surfaceContainerHighest: elevatedSurface,
      outline: isDark ? Colors.white.withOpacity(0.08) : AppColors.surfaceLightBorder,
      outlineVariant: isDark ? Colors.white.withOpacity(0.05) : const Color(0x0C000000),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? Colors.white : Colors.black,
      onInverseSurface: isDark ? Colors.black : Colors.white,
      background: scaffold,
      onBackground: onSurface,
    );

    final baseTextTheme = Typography.material2021(platform: TargetPlatform.iOS)
        .black
        .apply(
          bodyColor: onSurface,
          displayColor: onSurface,
        );

    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        height: 1.05,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.06,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.08,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.08,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.12,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        height: 1.15,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        height: 1.18,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05,
        height: 1.2,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.42,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.34,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.25,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
      ),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkSparkle.splashFactory,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      primaryColor: AppColors.primary,
      colorScheme: scheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
          letterSpacing: -0.5,
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
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : AppColors.surfaceLightBorder,
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: TextStyle(
          color: titleColor,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        contentTextStyle: TextStyle(
          color: onSurface.withOpacity(0.82),
          fontSize: 14,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withOpacity(isDark ? 0.82 : 0.94),
        surfaceTintColor: Colors.transparent,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : AppColors.surfaceLightBorder,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: titleColor,
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.10) : AppColors.surfaceLightBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
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
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : AppColors.surfaceLightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : AppColors.surfaceLightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.82),
            width: 1.4,
          ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
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
