import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Charte graphique officielle de MediCall Pro.
/// Style : Apple + Microsoft + Google Material 3. Épuré, moderne, professionnel.
class AppColors {
  AppColors._();

  static const Color bleuMedical = Color(0xFF0D47A1);
  static const Color vertEmeraude = Color(0xFF00A86B);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color grisAnthracite = Color(0xFF2E2E2E);

  static const Color fond = Color(0xFFF5F7FA);
  static const Color grisClair = Color(0xFFE3E7ED);
  static const Color erreur = Color(0xFFD32F2F);
  static const Color succes = vertEmeraude;
  static const Color attention = Color(0xFFFFA000);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.fond,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.bleuMedical,
        primary: AppColors.bleuMedical,
        secondary: AppColors.vertEmeraude,
        surface: AppColors.blanc,
        error: AppColors.erreur,
        brightness: Brightness.light,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.grisAnthracite,
        displayColor: AppColors.grisAnthracite,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.blanc,
        foregroundColor: AppColors.grisAnthracite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.grisAnthracite,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bleuMedical,
          foregroundColor: AppColors.blanc,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanc,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grisClair),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.grisClair),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.bleuMedical, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.blanc,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.grisClair),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.bleuMedical),
    );
  }
}

/// Rayons et espacements standardisés pour toute l'application.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double radius = 16;
}
