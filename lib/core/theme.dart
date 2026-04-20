import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const background = Color(0xFF07080B);
  static const backgroundAlt = Color(0xFF0D1118);
  static const backgroundLight = Color(0xFFF5F7FB);
  static const backgroundLightAlt = Color(0xFFECEFF6);

  static const surface = Color(0xFF141A24);
  static const surfaceElevated = Color(0xFF1B2431);
  static const surfaceGlass = Color(0xCC181F2B);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceLightAlt = Color(0xFFF8FAFD);

  static const primary = Color(0xFF86A2FF);
  static const primarySoft = Color(0xFF5A78EE);
  static const live = Color(0xFFFF5A52);
  static const success = Color(0xFF2CCB76);
  static const warning = Color(0xFFFFC857);

  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFA3A8B3);
  static const textPrimaryLight = Color(0xFF0B0D11);
  static const textSecondaryLight = Color(0xFF667085);

  static const surfaceLightBorder = Color(0x14000000);
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
      secondary: isDark ? AppColors.primarySoft : AppColors.primary,
      onSecondary: Colors.white,
      tertiary: isDark ? AppColors.success : const Color(0xFF0F9D58),
      error: AppColors.live,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      background: scaffold,
      onBackground: onSurface,
      surfaceContainerLowest: scaffold,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: elevatedSurface,
      surfaceContainerHighest: elevatedSurface,
      outline: isDark ? Colors.white.withOpacity(0.08) : AppColors.surfaceLightBorder,
      outlineVariant: isDark ? Colors.white.withOpacity(0.05) : const Color(0x0F000000),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? Colors.white : Colors.black,
      onInverseSurface: isDark ? Colors.black : Colors.white,
    );

    final base = Typography.material2021(platform: TargetPlatform.iOS).black.apply(
          bodyColor: onSurface,
          displayColor: onSurface,
        );

    final textTheme = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.6,
        height: 1.05,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.06,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.9,
        height: 1.08,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.08,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.1,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.12,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        height: 1.15,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
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
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.25,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
      ),
    );

    final iconTheme = IconThemeData(
      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      size: 22,
    );

    final baseButtonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
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
      iconTheme: iconTheme,
      primaryIconTheme: const IconThemeData(color: AppColors.primary, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: titleColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,
        iconTheme: IconThemeData(color: titleColor, size: 22),
        titleTextStyle: TextStyle(
          color: titleColor,
          fontSize: 23,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.55,
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
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : AppColors.surfaceLightBorder,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0x12000000),
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const MaterialStatePropertyAll(Size(0, 52)),
          padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
          shape: MaterialStatePropertyAll(baseButtonShape),
          backgroundColor: MaterialStatePropertyAll(isDark ? AppColors.primary : AppColors.primarySoft),
          foregroundColor: const MaterialStatePropertyAll(Colors.white),
          elevation: const MaterialStatePropertyAll(0),
          textStyle: MaterialStatePropertyAll(TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
            color: isDark ? Colors.white : Colors.white,
          )),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStatePropertyAll(isDark ? AppColors.primary : AppColors.primarySoft),
          shape: MaterialStatePropertyAll(baseButtonShape),
          textStyle: const MaterialStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const MaterialStatePropertyAll(Size(0, 52)),
          padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
          shape: MaterialStatePropertyAll(baseButtonShape),
          side: MaterialStatePropertyAll(BorderSide(color: isDark ? Colors.white.withOpacity(0.10) : AppColors.surfaceLightBorder)),
          foregroundColor: MaterialStatePropertyAll(onSurface),
          textStyle: const MaterialStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const MaterialStatePropertyAll(Size(0, 52)),
          padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
          shape: MaterialStatePropertyAll(baseButtonShape),
          backgroundColor: MaterialStatePropertyAll(isDark ? elevatedSurface : surface),
          foregroundColor: MaterialStatePropertyAll(onSurface),
          elevation: const MaterialStatePropertyAll(0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? Colors.white.withOpacity(0.06) : const Color(0x11000000),
        disabledColor: isDark ? Colors.white.withOpacity(0.04) : const Color(0x09000000),
        selectedColor: AppColors.primary.withOpacity(0.18),
        secondarySelectedColor: AppColors.primary.withOpacity(0.22),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        labelStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
        ),
        secondaryLabelStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
        ),
        brightness: brightness,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : AppColors.surfaceLightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : AppColors.surfaceLightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.55), width: 1.2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        iconColor: onSurface,
        textColor: onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.primary.withOpacity(0.18),
        labelTextStyle: MaterialStatePropertyAll(TextStyle(
          color: onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        )),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: isDark ? Colors.white.withOpacity(0.10) : const Color(0x14000000),
        circularTrackColor: isDark ? Colors.white.withOpacity(0.12) : const Color(0x14000000),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
