import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF12130F);
  static const muted = Color(0xFF686A63);
  static const canvas = Color(0xFFF8F8F4);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE7E8E1);
  static const lime = Color(0xFFB9EC18);
  static const limeDark = Color(0xFF5E7800);
  static const warning = Color(0xFFF39A32);
  static const protein = Color(0xFF437FE5);
  static const carbs = Color(0xFFF0A20C);
  static const fat = Color(0xFFF05678);
}

ThemeData buildTheme() {
  const colorScheme = ColorScheme.light(
    primary: AppColors.lime,
    onPrimary: AppColors.ink,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    outline: AppColors.line,
    error: Color(0xFFD93025),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: 'SF Pro Display',
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: AppColors.ink,
        fontSize: 42,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
      ),
      headlineMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 28,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w700,
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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.all(20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.lime,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.muted,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
