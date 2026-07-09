import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// MindWipe's typography system.
///
/// 🧠 LEARN: Flutter's [TextTheme] has a hierarchy of named styles:
/// displayLarge > displayMedium > headlineLarge > headlineMedium >
/// titleLarge > titleMedium > bodyLarge > bodyMedium > labelLarge > labelSmall
///
/// We use [Outfit] for headings (geometric, feels premium) and
/// [Inter] for body text (designed for screens, extremely legible).
class AppTypography {
  AppTypography._();

  /// The full text theme for MindWipe.
  ///
  /// Usage: Set this as [ThemeData.textTheme] in your MaterialApp.
  /// Then access styles with: Theme.of(context).textTheme.headlineLarge
  static TextTheme get textTheme {
    return TextTheme(
      // ─── Display (Large hero text, rarely used) ──────────────
      displayLarge: GoogleFonts.outfit(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),

      // ─── Headlines (Section headers) ─────────────────────────
      headlineLarge: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),

      // ─── Titles (Card titles, app bar) ───────────────────────
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),

      // ─── Body (Main content text) ────────────────────────────
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5, // Line height multiplier
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      ),

      // ─── Labels (Buttons, chips, captions) ───────────────────
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.textTertiary,
      ),
    );
  }
}
