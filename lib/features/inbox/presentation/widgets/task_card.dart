import 'package:flutter/material.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/widgets/glass_card.dart';

/// A single task card in the Inbox feed.
///
/// 🧠 LEARN: This widget uses [GlassCard] as its container and displays
/// the task title, a timestamp, and a completion indicator.
///
/// For now this is a [StatelessWidget] with hardcoded data.
/// In Phase 2, we'll wire it up to actual state management.
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      opacity: isCompleted ? 0.04 : 0.08,
      child: Row(
        children: [
          // ─── Completion Circle ──────────────────────────────
          GestureDetector(
            onTap: onCompleteTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.success.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.success
                      : AppColors.textTertiary,
                  width: 1.5,
                ),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.success,
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
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: isCompleted
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
