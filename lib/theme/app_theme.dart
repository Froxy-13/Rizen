import 'package:flutter/material.dart';

class AppColors {
  static const Color dustyRose = Color(0xFFc78283);
  static const Color softBlush = Color(0xFFf3d9dc);
  static const Color paleOak = Color(0xFFd7bea8);
  static const Color rosyTaupe = Color(0xFFb49286);
  static const Color mauveShadow = Color(0xFF744253);
  static const Color background = Color(0xFFf9f9f9);
  static const Color onSurface = Color(0xFF1a1c1c);
  static const Color onSurfaceVariant = Color(0xFF524343);
  static const Color error = Color(0xFFba1a1a);
  static const Color white = Color(0xFFffffff);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.dustyRose,
        onPrimary: AppColors.white,
        secondary: AppColors.softBlush,
        onSecondary: AppColors.mauveShadow,
        error: AppColors.error,
        surface: AppColors.background,
        onSurface: AppColors.onSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mauveShadow,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.01,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        hintStyle: TextStyle(color: AppColors.rosyTaupe),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.paleOak),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.paleOak),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.dustyRose, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}