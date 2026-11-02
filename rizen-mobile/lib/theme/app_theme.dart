import 'package:flutter/material.dart';

/// ============================================================
/// RIZEN — Design System v2 (Navy / Terracotta / Cream)
/// Refonte 07/2026 — basé sur les tokens Figma
/// ============================================================

class AppColors {
  // ── Backgrounds ─────────────────────────────
  static const Color background = Color(0xFFFAF9F9); // cream
  static const Color surface = Color(0xFFFFFFFF); // blanc pur (cards, inputs)
  static const Color surfaceContainerLow = Color(0xFFF5F3F3);
  static const Color white = Color(0xFFFFFFFF);

  // ── Primary (Terracotta — CTA) ──────────────
  static const Color primary = Color(0xFFFC7138);
  static const Color primaryLight = Color(0xFFFFDBCF);

  // ── Navy (nav, headings, texte fort) ─────────
  static const Color navy = Color(0xFF131B2D);

  // ── Texte ────────────────────────────────────
  static const Color onSurface = Color(0xFF1B1C1C);
  static const Color onSurfaceVariant = Color(0xFF45464C);
  static const Color rosyTaupe = Color(0xFF76777D); // gris secondaire/metadata

  // ── Accents ──────────────────────────────────
  static const Color link = Color(0xFF4A90D9);
  static const Color emerald = Color(0xFF00966B);

  // ── Bordures (usage minimal, design sans bordures) ─
  static const Color paleOak = Color(0xFFC6C6CD);

  // ── Aliases legacy (compat écrans déjà stylés) ─
  static const Color mauveShadow = navy; // ancien "texte fort / noir"
  static const Color dustyRose = primary; // ancien "orange primaire"
  static const Color softBlush = Color(0xFFF0F0F0); // chips / placeholders

  // ── Status ───────────────────────────────────
  static const Color success = emerald;
  static const Color error = Color(0xFFBA1A1A);
}

class AppRadius {
  static const double sm = 4;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

class AppSpacing {
  static const double containerMargin = 20;
  static const double gutter = 12;
  static const double stackSm = 8;
  static const double stackMd = 16;
  static const double stackLg = 24;
  static const double cardPadding = 16;
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.navy.withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> nav = [
    BoxShadow(
      color: AppColors.navy.withOpacity(0.25),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];
}

class AppTextStyles {
  static const String fontFamily = 'PlusJakartaSans';

  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.64,
    color: AppColors.navy,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.29,
    letterSpacing: -0.56,
    color: AppColors.navy,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.navy,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: AppColors.onSurface,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.38,
    color: AppColors.rosyTaupe,
  );

  static const TextStyle labelCaps = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.45,
    letterSpacing: 0.55,
    color: AppColors.rosyTaupe,
  );
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        background: AppColors.background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.navy,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.link,
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
          letterSpacing: 0.5,
        ),
        hintStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          color: AppColors.rosyTaupe,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.paleOak,
        thickness: 1,
      ),
      // ── Thème global des popups (AlertDialog) ────────────────
      // Sans ça, Material 3 teinte légèrement le fond du dialogue avec
      // la couleur primaire à cause de l'élévation par défaut — d'où le
      // rendu rose/pêche moche sur fond blanc. surfaceTintColor à
      // transparent + fond crème explicite corrige ça partout d'un coup.
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );
  }
}