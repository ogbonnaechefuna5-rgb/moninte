import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Core surfaces (dark)
  static const Color background = Color(0xFF0D1F17);
  static const Color surfaceDark = Color(0xFF162D20);
  static const Color surfaceLight = Color(0xFF1E3D2A);
  static const Color primaryGreen = Color(0xFF1A4D3A);

  // Core surfaces (light)
  static const Color backgroundLight = Color(0xFFF4F9F1);
  static const Color surfaceDarkLight = Color(0xFFE2EFE0);
  static const Color surfaceLightLight = Color(0xFFD0E8CC);

  // Accent
  static const Color accent = Color(0xFFA8FF3E);

  // Text (dark)
  static const Color textPrimary = Color(0xFFF5F5F0);
  static const Color textSecondary = Color(0xFF8A9E90);

  // Text (light)
  static const Color textPrimaryLight = Color(0xFF0D1F17);
  static const Color textSecondaryLight = Color(0xFF4A6655);

  // Status
  static const Color destructive = Color(0xFFFF4D4D);
  static const Color warning = Color(0xFFFFB830);
  static const Color success = Color(0xFF4DFF91);

  // Chart colors
  static const Color chart1 = Color(0xFFFF8C42);
  static const Color chart2 = Color(0xFF4D9FFF);
  static const Color chart3 = Color(0xFFA855F7);
  static const Color chart4 = Color(0xFFFFB830);
  static const Color chart5 = Color(0xFFFF69B4);

  // Borders
  static Color borderDefault = Colors.white.withValues(alpha: 0.1);
  static Color borderAccent = accent.withValues(alpha: 0.3);
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.primaryGreen,
          surface: AppColors.surfaceDark,
          error: AppColors.destructive,
          onPrimary: AppColors.background,
          onSecondary: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
          onError: AppColors.textPrimary,
        ),
        textTheme: _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary),
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.background, elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: AppColors.background),
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          secondary: AppColors.primaryGreen,
          surface: AppColors.surfaceDarkLight,
          error: AppColors.destructive,
          onPrimary: AppColors.background,
          onSecondary: AppColors.textPrimaryLight,
          onSurface: AppColors.textPrimaryLight,
          onError: Colors.white,
        ),
        textTheme: _buildTextTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.backgroundLight, elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: AppColors.backgroundLight),
      );

  static TextTheme _buildTextTheme(Color primary, Color secondary) => TextTheme(
        displayLarge: GoogleFonts.syne(fontSize: 34, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
        displayMedium: GoogleFonts.syne(fontSize: 28, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.3),
        headlineLarge: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.3),
        headlineMedium: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: primary),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: primary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: primary),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: primary),
        labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400, color: secondary),
      );

  static TextStyle get mono => GoogleFonts.inter(
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AppColors.textPrimary,
      );

  static TextStyle monoSized(double size, {Color? color, FontWeight? weight}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? AppColors.textPrimary,
      );
}
