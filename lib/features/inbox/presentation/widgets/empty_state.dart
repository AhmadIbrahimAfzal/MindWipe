import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindwipe/core/theme/app_colors.dart';

/// Elegant animated empty state for when the Inbox has no tasks.
///
/// Features a breathing pulse animation on the icon and staggered
/// fade-in on the text to make the empty state feel alive and premium.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Breathing Pulse Icon ─────────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.02),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.bubble_chart_rounded,
                size: 32,
                color: AppColors.textTertiary,
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scaleXY(
                  begin: 1.0,
                  end: 1.08,
                  duration: const Duration(milliseconds: 2400),
                  curve: Curves.easeInOut,
                )
                .then()
                .shimmer(
                  duration: const Duration(milliseconds: 1800),
                  color: Colors.white.withValues(alpha: 0.04),
                ),

            const SizedBox(height: 28),

            Text(
              'Your mind is clear',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                )
                .slideY(
                  begin: 0.15,
                  end: 0,
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 10),

            Text(
              'Pull up + to dump a thought',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 450),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                )
                .slideY(
                  begin: 0.15,
                  end: 0,
                  delay: const Duration(milliseconds: 450),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                ),
          ],
        ),
      ),
    );
  }
}
