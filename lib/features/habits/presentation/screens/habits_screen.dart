import 'package:flutter/material.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/widgets/glass_card.dart';

/// Habits screen placeholder.
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Habits',
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '2 rituals pending for today',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Habit pills
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildHabitCard(
                title: 'Hit 100g Protein target',
                progress: 0.7,
                done: false,
              ),
              _buildHabitCard(
                title: 'Take Creatine',
                progress: 1.0,
                done: true,
              ),
              _buildHabitCard(
                title: 'Read 10 pages',
                progress: 0.3,
                done: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCard({
    required String title,
    required double progress,
    required bool done,
  }) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      opacity: done ? 0.03 : 0.06,
      child: Row(
        children: [
          // Muted completion check
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.textSecondary.withValues(alpha: 0.15) : Colors.transparent,
              border: Border.all(
                color: done ? AppColors.textSecondary : AppColors.textTertiary,
                width: 1.5,
              ),
            ),
            child: done
                ? Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // Habit Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: done ? AppColors.textTertiary : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                // Simple Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: done ? AppColors.textSecondary : AppColors.accentPrimaryMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
