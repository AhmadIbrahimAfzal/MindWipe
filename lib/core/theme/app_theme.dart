import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// MindWipe's theme configuration.
///
/// 🧠 LEARN: [ThemeData] is the single source of truth for your app's visual
/// identity. Every widget in Flutter looks at the nearest [Theme] in the
/// widget tree. By setting [ThemeData] at the root [MaterialApp], every
/// widget automatically inherits these styles.
///
/// We customize [colorScheme], [textTheme], and individual component themes
/// (AppBar, InputDecoration, Card, etc.) to create a cohesive look.
class AppTheme {
  AppTheme._();

  /// The dark theme for MindWipe (MVP: dark-only).
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ── Color Scheme ──────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPrimary,
        onPrimary: AppColors.backgroundDeep,
        secondary: AppColors.accentSecondary,
        onSecondary: AppColors.backgroundDeep,
        surface: AppColors.backgroundPrimary,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.backgroundDeep,
      ),

      // ── Scaffold ──────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.backgroundPrimary,

      // ── Typography ────────────────────────────────────────────
      textTheme: AppTypography.textTheme,

      // ── App Bar ───────────────────────────────────────────────
      // Transparent + no elevation = blends with our custom backgrounds
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // ── Input Decoration (for the quick-add bar) ──────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // ── Cards ─────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.backgroundElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Dividers ──────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 0.5,
        space: 0,
      ),

      // ── Splash / Ripple ───────────────────────────────────────
      // Subtle ripple effect consistent with the glass aesthetic
      splashFactory: InkSparkle.splashFactory,
      splashColor: AppColors.glassWhite,
      highlightColor: Colors.transparent,
    );
  }
}
