import 'dart:ui';

/// MindWipe's curated color palette — Black & Grey aesthetic.
///
/// 🧠 LEARN: We shifted from navy to pure black/grey for a more
/// premium, iOS-inspired look. The key is using subtle grey variations
/// to create depth without any color — like layers of dark glass.
class AppColors {
  AppColors._();

  // ─── Background Layers ──────────────────────────────────────────
  // Pure black base → dark grey for depth → slightly lighter for surfaces
  static const Color backgroundDeep = Color(0xFF000000);     // Pure black
  static const Color backgroundPrimary = Color(0xFF0A0A0A);  // Near-black
  static const Color backgroundElevated = Color(0xFF141414);  // Dark grey cards
  static const Color backgroundSurface = Color(0xFF1C1C1E);  // iOS-style surface

  // ─── Glass / Overlay ────────────────────────────────────────────
  static const Color glassWhite = Color(0x1AFFFFFF);       // ~10% white
  static const Color glassBorder = Color(0x22FFFFFF);      // ~13% white
  static const Color glassHighlight = Color(0x0DFFFFFF);   // ~5% white
  static const Color glassFill = Color(0x14FFFFFF);        // ~8% white — card fill

  // ─── Accent Colors ─────────────────────────────────────────────
  // Muted white-grey as primary accent — nothing flashy
  static const Color accentPrimary = Color(0xFFE0E0E0);     // Soft white
  static const Color accentPrimaryMuted = Color(0xFF8E8E93); // iOS system grey

  // Subtle warm accent for special moments
  static const Color accentSecondary = Color(0xFF9A9A9A);    // Medium grey
  static const Color accentSecondaryMuted = Color(0xFF636366);

  // Success: Soft muted green
  static const Color success = Color(0xFF32D74B);
  static const Color successGlow = Color(0x3332D74B);

  // Warning: Muted amber
  static const Color warning = Color(0xFFFFD60A);

  // Error: iOS-style red
  static const Color error = Color(0xFFFF453A);

  // ─── Text Colors ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF2F2F7);      // iOS primary label
  static const Color textSecondary = Color(0xFF8E8E93);     // iOS secondary label
  static const Color textTertiary = Color(0xFF48484A);      // iOS tertiary label
  static const Color textDisabled = Color(0xFF2C2C2E);      // Disabled

  // ─── Gradients ─────────────────────────────────────────────────
  static const List<Color> backgroundGradient = [
    Color(0xFF000000),
    Color(0xFF0A0A0A),
    Color(0xFF111111),
  ];

  // Wheel gradient — subtle grey shimmer
  static const List<Color> wheelGradient = [
    Color(0xFF1C1C1E),
    Color(0xFF2C2C2E),
    Color(0xFF1C1C1E),
  ];

  // Accent gradient for the add button
  static const List<Color> accentGradient = [
    Color(0xFF3A3A3C),
    Color(0xFF2C2C2E),
  ];

  // Completion fill gradient
  static const List<Color> completionGradient = [
    Color(0xFF32D74B),
    Color(0xFF30B84B),
  ];
}
