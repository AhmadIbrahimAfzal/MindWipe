import 'package:flutter/material.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/widgets/glass_card.dart';

/// A floaty, pill-shaped task card with fluid micro-animations.
///
/// Completion transitions use smooth AnimatedContainer color shifts
/// and an AnimatedScale on the check icon for a satisfying "pop" effect.
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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      opacity: isCompleted ? 0.55 : 1.0,
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        borderRadius: 28,
        opacity: isCompleted ? 0.03 : 0.07,
        borderOpacity: isCompleted ? 0.04 : 0.10,
        child: Row(
          children: [
            // ─── Completion Circle with Pop Animation ──────────
            GestureDetector(
              onTap: onCompleteTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
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
                  child: AnimatedScale(
                    scale: isCompleted ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // ─── Task Content ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOut,
                    style: (textTheme.bodyLarge ?? const TextStyle()).copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: AppColors.textTertiary,
                      color: isCompleted
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                    child: Text(title),
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
      ),
    );
  }
}
