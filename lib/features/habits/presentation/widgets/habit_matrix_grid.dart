import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HabitKit-style Dot Matrix Consistency Grid.
///
/// Displays a grid of rounded square dots representing consecutive days.
/// Completed days glow brightly with the habit's vibrant color.
/// Inactive days are subdued dark grey dots.
class HabitMatrixGrid extends StatelessWidget {
  const HabitMatrixGrid({
    super.key,
    required this.completedDates,
    required this.color,
    this.numWeeks = 18,
    this.rows = 6,
    this.onDateTap,
    this.interactive = false,
  });

  final Set<String> completedDates;
  final Color color;
  final int numWeeks;
  final int rows;
  final ValueChanged<String>? onDateTap;
  final bool interactive;

  static String formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr = formatDate(today);
    final totalCells = numWeeks * rows;

    // Generate list of dates from oldest (top-left) to newest (bottom-right)
    final dates = List.generate(totalCells, (index) {
      final daysAgo = (totalCells - 1) - index;
      return today.subtract(Duration(days: daysAgo));
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Calculate cell size & spacing to fit perfectly
        final spacing = 3.5;
        final cellSize = ((availableWidth - (numWeeks - 1) * spacing) / numWeeks).clamp(6.0, 14.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(rows, (rowIndex) {
            return Padding(
              padding: EdgeInsets.only(bottom: rowIndex == rows - 1 ? 0 : spacing),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(numWeeks, (colIndex) {
                  final cellIndex = colIndex * rows + rowIndex;
                  if (cellIndex >= dates.length) return const SizedBox.shrink();

                  final date = dates[cellIndex];
                  final dateStr = formatDate(date);
                  final isCompleted = completedDates.contains(dateStr);
                  final isToday = dateStr == todayStr;
                  final isFuture = date.isAfter(today);

                  return GestureDetector(
                    onTap: (interactive && !isFuture && onDateTap != null)
                        ? () {
                            HapticFeedback.selectionClick();
                            onDateTap!(dateStr);
                          }
                        : null,
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? color
                            : (isFuture
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(cellSize * 0.28),
                        border: isToday && !isCompleted
                            ? Border.all(
                                color: color.withValues(alpha: 0.8),
                                width: 1.0,
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}
