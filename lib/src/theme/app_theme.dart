import 'package:flutter/material.dart';

// Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5
// Genre: vibrant health utility · tone: energetic, trustworthy, food-centric
// Anchor: deep emerald + fresh lime · fingerprint: photo-led food journal

abstract final class AppColors {
  static const ink = Color(0xFF102019);
  static const muted = Color(0xFF53635A);
  static const canvas = Color(0xFFF3F7F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFE8F1EB);
  static const line = Color(0xFFD5E3DA);
  static const separator = Color(0x1A0B3D29);
  static const brand = Color(0xFF087A4C);
  static const brandStrong = Color(0xFF055C3A);
  static const brandSoft = Color(0xFFDDF4E7);
  static const lime = Color(0xFFB6F04A);
  static const limeSoft = Color(0xFFE5F8B8);
  static const limeDark = brand;
  static const warning = Color(0xFFE87514);
  static const reviewSurface = Color(0xFFFFF1DC);
  static const reviewInk = Color(0xFF7B3F08);
  static const destructive = Color(0xFFBA1A1A);
  static const onDark = Color(0xFFFFFFFF);
  static const quoteSurface = Color(0xFFE7F5EC);
  static const selectedSurface = Color(0xFFE2F5E8);
  static const protein = Color(0xFF1769AA);
  static const carbs = Color(0xFFD46A0A);
  static const fat = Color(0xFFB23A67);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const x28 = 28.0;
  static const xxl = 32.0;
  static const section = 40.0;
  static const x48 = 48.0;
  static const x56 = 56.0;
  static const x64 = 64.0;
}

abstract final class AppRadius {
  static const small = 6.0;
  static const medium = 10.0;
  static const large = 14.0;
  static const input = 16.0;
  static const feature = 20.0;
  static const compactCard = 20.0;
  static const standardCard = 24.0;
  static const heroCard = 28.0;
}

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x12055C3A), blurRadius: 24, offset: Offset(0, 7)),
    BoxShadow(color: Color(0x0A055C3A), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const floating = <BoxShadow>[
    BoxShadow(color: Color(0x26055C3A), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 280);
}

abstract final class AppTouchTarget {
  static const minimum = 48.0;
}

ThemeData buildTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppColors.brand,
    onPrimary: AppColors.onDark,
    primaryContainer: AppColors.brandSoft,
    onPrimaryContainer: AppColors.brandStrong,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    secondaryContainer: AppColors.limeSoft,
    onSecondaryContainer: AppColors.ink,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    surfaceContainerHighest: AppColors.surfaceMuted,
    outline: AppColors.line,
    error: AppColors.destructive,
    onError: AppColors.onDark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: AppColors.ink,
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
      ),
      headlineMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 28,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 21,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
      labelLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    dividerColor: AppColors.line,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
        side: BorderSide(color: AppColors.line),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.limeSoft,
      elevation: 0,
      height: 72,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onDark,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.muted,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.feature),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(AppTouchTarget.minimum),
      ),
    ),
  );
}
