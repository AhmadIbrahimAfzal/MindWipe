import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable glassmorphic container widget.
///
/// 🧠 LEARN: This is the core of MindWipe's visual identity.
/// Glassmorphism = background blur + translucent fill + subtle border.
///
/// How it works:
/// 1. [ClipRRect] clips everything to rounded corners
/// 2. [BackdropFilter] applies a blur to whatever is BEHIND this widget
/// 3. A [Container] with a low-opacity fill creates the "frosted" surface
/// 4. A subtle border makes the edges visible against the blurred background
///
/// This is a [StatelessWidget] because it has no internal state — it just
/// takes configuration props and renders pixels.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blurAmount = 24,
    this.opacity = 0.08,
    this.borderOpacity = 0.15,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  /// The content inside the glass card
  final Widget child;

  /// Corner radius — higher = more rounded
  final double borderRadius;

  /// How much to blur the background (higher = more frosted)
  final double blurAmount;

  /// Opacity of the white fill (0 = invisible, 1 = solid white)
  final double opacity;

  /// Opacity of the border (0 = no border, 1 = solid white border)
  final double borderOpacity;

  /// Internal padding
  final EdgeInsets padding;

  /// External margin
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        // Step 1: Clip to rounded rectangle
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          // Step 2: Blur whatever is behind this widget
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: Container(
            // Step 3: Semi-transparent fill + border
            padding: padding,
            decoration: BoxDecoration(
              // The "frosted glass" fill
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: borderOpacity),
                width: 0.5,
              ),
              // Subtle inner glow at the top edge
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: opacity + 0.04),
                  Colors.white.withValues(alpha: opacity - 0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
