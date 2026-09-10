import 'dart:ui';
import 'package:flutter/material.dart';

/// A liquid-feel glassmorphic container.
///
/// 🧠 LEARN: Updated for a more "floaty" iOS aesthetic — higher border
/// radius for pill shapes, softer edges, and a subtle shadow that makes
/// cards feel like they're hovering above the background.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.blurAmount = 0,
    this.opacity = 0.06,
    this.borderOpacity = 0.08,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.enableShadow = true,
  });

  final Widget child;
  final double borderRadius;
  final double blurAmount;
  final double opacity;
  final double borderOpacity;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool enableShadow;

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: borderOpacity),
          width: 0.5,
        ),
      ),
      child: child,
    );

    if (blurAmount > 0) {
      cardContent = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
        ),
        child: cardContent,
      );
    }

    return Padding(
      padding: margin,
      child: Container(
        decoration: enableShadow
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      ),
    );
  }
}
