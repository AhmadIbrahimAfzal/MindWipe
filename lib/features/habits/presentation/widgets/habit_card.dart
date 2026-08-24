import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/features/habits/domain/entities/habit.dart';
import 'package:mindwipe/features/habits/presentation/providers/habits_provider.dart';
import 'package:mindwipe/features/habits/presentation/widgets/edit_habit_sheet.dart';
import 'package:mindwipe/features/habits/presentation/widgets/habit_icon_helper.dart';
import 'package:mindwipe/features/habits/presentation/widgets/habit_matrix_grid.dart';

/// Aesthetic Habit Card matching the HabitKit reference design.
///
/// Features:
/// - Tapping the Icon or Name opens the Edit Habit Sheet.
/// - Tapping any day tile in the grid toggles/fulfills that day's habit.
/// - Tapping the right checkmark button toggles today's habit.
class HabitCard extends ConsumerWidget {
  const HabitCard({
    super.key,
    required this.habit,
  });

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitColor = Color(habit.colorValue);
    final isCompletedToday = habit.isCompletedToday();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Row (Tap Name/Icon to Edit) ───────────
          Row(
            children: [
              // Icon Badge (Click to Edit)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => EditHabitSheet(habit: habit),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: habitColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    HabitIconHelper.getIcon(habit.iconKey),
                    color: habitColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Description (Click to Edit)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => EditHabitSheet(habit: habit),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          habit.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Checkmark Action Button for Today
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(habitsProvider.notifier).toggleToday(habit.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompletedToday
                        ? habitColor
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: isCompletedToday
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: isCompletedToday
                          ? (habitColor.computeLuminance() > 0.6
                              ? Colors.black
                              : Colors.white)
                          : AppColors.textTertiary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ─── Dot Matrix Consistency Grid (Tap Tiles to Toggle) ─
          HabitMatrixGrid(
            completedDates: habit.completedDates,
            color: habitColor,
            numWeeks: 18,
            rows: 6,
            interactive: true,
            onDateTap: (dateStr) {
              ref.read(habitsProvider.notifier).toggleDate(habit.id, dateStr);
            },
          ),
        ],
      ),
    );
  }
}
