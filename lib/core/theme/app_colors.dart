import 'dart:ui';

/// MindWipe's curated color palette.
///
/// All colors are chosen for a dark, glassmorphic aesthetic.
/// We use HSL thinking — hue for identity, saturation for vibrancy,
/// lightness for hierarchy.
///
/// 🧠 LEARN: In Flutter, [Color] takes ARGB hex values.
/// The format is 0xAARRGGBB where AA = alpha (opacity).
/// We use Color.fromRGBO() and Color.fromARGB() for readability.
class AppColors {
  AppColors._(); // Prevent instantiation — this is a utility class

  // ─── Background Layers ──────────────────────────────────────────
  // Deep navy-black base → slightly lighter for cards → lighter for elevated surfaces
  static const Color backgroundDeep = Color(0xFF0A0E1A);    // Deepest background
  static const Color backgroundPrimary = Color(0xFF0F1425);  // Main screen background
  static const Color backgroundElevated = Color(0xFF161B2E); // Cards, bottom sheets
  static const Color backgroundSurface = Color(0xFF1C2238);  // Elevated surfaces

  // ─── Glass / Overlay ────────────────────────────────────────────
  // For glassmorphic containers — white at very low opacity
  static const Color glassWhite = Color(0x1AFFFFFF);       // ~10% white
  static const Color glassBorder = Color(0x33FFFFFF);      // ~20% white (subtle border)
  static const Color glassHighlight = Color(0x0DFFFFFF);   // ~5% white (inner highlight)

  // ─── Accent Colors ─────────────────────────────────────────────
  // Primary: Soft cyan — calming, modern, high contrast on dark
  static const Color accentPrimary = Color(0xFF6EC6FF);    // Soft cyan-blue
  static const Color accentPrimaryMuted = Color(0xFF3A7CA5); // Muted version for less emphasis

  // Secondary: Lavender — warmth, pairs beautifully with cyan
  static const Color accentSecondary = Color(0xFFB39DDB);  // Soft lavender
  static const Color accentSecondaryMuted = Color(0xFF7E6DA0);

  // Success: Soft mint green — for completions
  static const Color success = Color(0xFF81C784);          // Muted green
  static const Color successGlow = Color(0x3381C784);      // Green with glow opacity

  // Warning: Warm amber
  static const Color warning = Color(0xFFFFB74D);

  // Error: Soft coral — not aggressive red
  static const Color error = Color(0xFFEF9A9A);

  // ─── Text Colors ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F5);      // Near-white, slight blue tint
  static const Color textSecondary = Color(0xFFB0B5C9);    // Muted for subtitles
  static const Color textTertiary = Color(0xFF6B7194);     // Timestamps, hints
  static const Color textDisabled = Color(0xFF3D4260);     // Disabled/faded states

  // ─── Gradients ─────────────────────────────────────────────────
  // Used for background and accent elements
  static const List<Color> backgroundGradient = [
    Color(0xFF0A0E1A),
    Color(0xFF0F1425),
    Color(0xFF151A30),
  ];

  // Accent gradient for buttons, progress indicators
  static const List<Color> accentGradient = [
    Color(0xFF6EC6FF),
    Color(0xFFB39DDB),
  ];

  // Completion fill gradient (for the habit pill animation)
  static const List<Color> completionGradient = [
    Color(0xFF6EC6FF),
    Color(0xFF81C784),
  ];
}
