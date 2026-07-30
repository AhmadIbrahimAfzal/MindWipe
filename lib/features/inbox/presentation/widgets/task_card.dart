import 'package:flutter/material.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/widgets/glass_card.dart';

/// A floaty, pill-shaped task card.
///
/// 🧠 LEARN: The pill shape comes from a very high [borderRadius] (28+).
/// Combined with the floating shadow from [GlassCard], each card feels
/// like a liquid bubble sitting on the screen — inspired by iOS widgets.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.title,
    required this.timestamp,
    this.isCompleted = false,
    this.onTap,
    this.onCompleteTap,
  });

  final String title;
  final String timestamp;
  final bool isCompleted;
  final VoidCallback? onTap;
  final VoidCallback? onCompleteTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      borderRadius: 28,
      opacity: isCompleted ? 0.03 : 0.07,
      borderOpacity: isCompleted ? 0.04 : 0.10,
      child: Row(
        children: [
          // ─── Completion Circle ──────────────────────────────
          GestureDetector(
            onTap: onCompleteTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.textSecondary.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.textSecondary
                      : AppColors.textTertiary.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    )
                  : null,
            ),
          ),

          const SizedBox(width: 16),

          // ─── Task Content ──────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textTertiary,
                    color: isCompleted
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timestamp,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
