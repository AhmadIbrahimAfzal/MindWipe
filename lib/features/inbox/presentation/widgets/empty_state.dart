import 'package:flutter/material.dart';
import 'package:mindwipe/core/theme/app_colors.dart';

/// An elegant empty state illustration for when the Inbox has no tasks.
///
/// 🧠 LEARN: Empty states are crucial UX — they tell users what to do next.
/// Instead of a boring "No tasks" text, we show a visual that encourages
/// the user to add their first thought.
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
            // ─── Abstract Icon ─────────────────────────────────
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPrimary.withValues(alpha: 0.15),
                    AppColors.accentPrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Icon(
                Icons.bubble_chart_rounded,
                size: 40,
                color: AppColors.accentPrimary,
              ),
            ),

            const SizedBox(height: 24),

            // ─── Title ─────────────────────────────────────────
            Text(
              'Your mind is clear',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // ─── Subtitle ──────────────────────────────────────
            Text(
              'Dump a thought below to start filling your inbox',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
