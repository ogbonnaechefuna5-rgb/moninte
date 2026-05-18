import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Dark surface palette ──
  static const Color background = Color(0xFF0D1F17);
  static const Color surfaceDark = Color(0xFF162D20);
  static const Color surfaceLight = Color(0xFF1E3D2A);
  static const Color primaryGreen = Color(0xFF1A4D3A);

  // ── Light surface palette ──
  static const Color backgroundLight = Color(0xFFE8EFE8);
  static const Color surfaceDarkLight = Color(0xFFD4E0D0);
  static const Color surfaceLightLight = Color(0xFFC4D4BF);
  static const Color primaryGreenLight = Color(0xFF1A5C3A);

  // ── Accent (same in both modes) ──
  static const Color accent = Color(0xFFA8FF3E);

  // ── Text (dark mode) ──
  static const Color textPrimary = Color(0xFFF5F5F0);
  static const Color textSecondary = Color(0xFF8A9E90);

  // ── Text (light mode) ──
  static const Color textPrimaryLight = Color(0xFF0D1F17);
  static const Color textSecondaryLight = Color(0xFF2D4A38);

  // ── Status (same in both modes) ──
  static const Color destructive = Color(0xFFFF4D4D);
  static const Color warning = Color(0xFFFFB830);
  static const Color success = Color(0xFF4DFF91);

  // ── Chart colours ──
  static const Color chart1 = Color(0xFFFF8C42);
  static const Color chart2 = Color(0xFF4D9FFF);
  static const Color chart3 = Color(0xFFA855F7);
  static const Color chart4 = Color(0xFFFFB830);
  static const Color chart5 = Color(0xFFFF69B4);

  // ── Static border helpers (dark-mode defaults, kept for const contexts) ──
  static Color borderDefault = Colors.white.withValues(alpha: 0.1);
  static Color borderAccent = accent.withValues(alpha: 0.3);

  // ── Context-aware colour resolver ──
  // Use these in widgets that have a BuildContext so colours adapt to the
  // active theme automatically.
  static _ThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const _ThemeColors._dark() : const _ThemeColors._light();
  }
}

/// Resolved colour set for the active theme.
/// Obtain via [AppColors.of(context)].
class _ThemeColors {
  final Color background;
  final Color surfaceDark;
  final Color surfaceLight;
  final Color primaryGreen;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderDefault;
  final Color borderAccent;
  final bool isDark;

  const _ThemeColors._dark()
      : background = AppColors.background,
        surfaceDark = AppColors.surfaceDark,
        surfaceLight = AppColors.surfaceLight,
        primaryGreen = AppColors.primaryGreen,
        textPrimary = AppColors.textPrimary,
        textSecondary = AppColors.textSecondary,
        borderDefault = const Color(0x1AFFFFFF), // white 10%
        borderAccent = const Color(0x4DA8FF3E),  // accent 30%
        isDark = true;

  const _ThemeColors._light()
      : background = AppColors.backgroundLight,
        surfaceDark = AppColors.surfaceDarkLight,
        surfaceLight = AppColors.surfaceLightLight,
        primaryGreen = AppColors.primaryGreenLight,
        textPrimary = AppColors.textPrimaryLight,
        textSecondary = AppColors.textSecondaryLight,
        borderDefault = const Color(0x1A000000), // black 10%
        borderAccent = const Color(0x4DA8FF3E),  // accent 30%
        isDark = false;

  // Accent is the same in both modes
  Color get accent => AppColors.accent;
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
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.background),
      );

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          secondary: AppColors.primaryGreen,
          surface: AppColors.surfaceDarkLight,
          error: AppColors.destructive,
          onPrimary: Colors.white,
          onSecondary: AppColors.textPrimaryLight,
          onSurface: AppColors.textPrimaryLight,
          onError: Colors.white,
        ),
        textTheme: _buildTextTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
        appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.backgroundLight, elevation: 0),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: AppColors.backgroundLight),
      );

  static TextTheme _buildTextTheme(Color primary, Color secondary) =>
      TextTheme(
        displayLarge: GoogleFonts.syne(
            fontSize: 34, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
        displayMedium: GoogleFonts.syne(
            fontSize: 28, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.3),
        headlineLarge: GoogleFonts.syne(
            fontSize: 24, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.3),
        headlineMedium: GoogleFonts.syne(
            fontSize: 20, fontWeight: FontWeight.w600, color: primary),
        titleLarge: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w500, color: primary),
        titleMedium: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w500, color: primary),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w400, color: primary),
        bodyMedium: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w400, color: primary),
        bodySmall: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
        labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w500, color: primary),
        labelSmall: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w400, color: secondary),
      );

  static TextStyle get mono => GoogleFonts.inter(
        fontFeatures: const [FontFeature.tabularFigures()],
        color: AppColors.textPrimary,
      );

  static TextStyle get tagline => GoogleFonts.dancingScript(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.accent,
        letterSpacing: 1.2,
      );

  static TextStyle monoSized(double size, {Color? color, FontWeight? weight, BuildContext? context}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color ?? (context != null ? AppColors.of(context).textPrimary : AppColors.textPrimary),
      );
}
