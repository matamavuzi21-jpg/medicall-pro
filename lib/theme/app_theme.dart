import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color bleuMedical = Color(0xFF0B3D78);
  static const Color vertEmeraude = Color(0xFF049B6B);
  static const Color blanc = Color(0xFFFFFFFF);
  static const Color grisAnthracite = Color(0xFF24262B);

  static const Color fond = Color(0xFFF6F2EA);
  static const Color grisClair = Color(0xFFE6E1D6);
  static const Color erreur = Color(0xFFC13F2E);
  static const Color succes = vertEmeraude;
  static const Color attention = Color(0xFFE2921F);
}

class AppTypography {
  AppTypography._();

  static TextStyle wordmark({double fontSize = 26, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.bleuMedical,
      height: 1.05,
    );
  }

  static TextStyle mono({
    double fontSize = 14,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: weight,
      color: color ?? AppColors.grisAnthracite,
    );
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final baseTextTheme = GoogleFonts.interTextTheme();

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
        titleTextStyle: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
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
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
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

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double radius = 16;
}
