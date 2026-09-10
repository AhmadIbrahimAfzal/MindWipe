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
        final spacing = 3.5;
        final cellSize = ((availableWidth - (numWeeks - 1) * spacing) / numWeeks).clamp(6.0, 14.0);
        final totalHeight = rows * cellSize + (rows - 1) * spacing;

        final paintWidget = CustomPaint(
          size: Size(availableWidth, totalHeight),
          painter: _HabitMatrixPainter(
            numWeeks: numWeeks,
            rows: rows,
            cellSize: cellSize,
            spacing: spacing,
            dates: dates,
            completedDates: completedDates,
            color: color,
            todayStr: todayStr,
            today: today,
          ),
        );

        if (!interactive || onDateTap == null) {
          return paintWidget;
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final colIndex = (details.localPosition.dx / (cellSize + spacing)).floor();
            final rowIndex = (details.localPosition.dy / (cellSize + spacing)).floor();
            if (colIndex >= 0 && colIndex < numWeeks && rowIndex >= 0 && rowIndex < rows) {
              final cellIndex = colIndex * rows + rowIndex;
              if (cellIndex < dates.length) {
                final date = dates[cellIndex];
                if (!date.isAfter(today)) {
                  HapticFeedback.selectionClick();
                  onDateTap!(formatDate(date));
                }
              }
            }
          },
          child: paintWidget,
        );
      },
    );
  }
}

class _HabitMatrixPainter extends CustomPainter {
  _HabitMatrixPainter({
    required this.numWeeks,
    required this.rows,
    required this.cellSize,
    required this.spacing,
    required this.dates,
    required this.completedDates,
    required this.color,
    required this.todayStr,
    required this.today,
  })  : _completedPaint = Paint()..color = color,
        _inactivePaint = Paint()..color = Colors.white.withValues(alpha: 0.05),
        _todayBorderPaint = Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

  final int numWeeks;
  final int rows;
  final double cellSize;
  final double spacing;
  final List<DateTime> dates;
  final Set<String> completedDates;
  final Color color;
  final String todayStr;
  final DateTime today;

  final Paint _completedPaint;
  final Paint _inactivePaint;
  final Paint _todayBorderPaint;

  @override
  void paint(Canvas canvas, Size size) {
    final cornerRadius = Radius.circular(cellSize * 0.28);

    for (int col = 0; col < numWeeks; col++) {
      final left = col * (cellSize + spacing);
      for (int row = 0; row < rows; row++) {
        final cellIndex = col * rows + row;
        if (cellIndex >= dates.length) continue;

        final date = dates[cellIndex];
        final dateStr = HabitMatrixGrid.formatDate(date);
        final isCompleted = completedDates.contains(dateStr);
        final isToday = dateStr == todayStr;
        final isFuture = date.isAfter(today);

        final top = row * (cellSize + spacing);
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, cellSize, cellSize),
          cornerRadius,
        );

        if (isCompleted) {
          canvas.drawRRect(rrect, _completedPaint);
        } else if (!isFuture) {
          canvas.drawRRect(rrect, _inactivePaint);
        }

        if (isToday && !isCompleted) {
          canvas.drawRRect(rrect, _todayBorderPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HabitMatrixPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.completedDates != completedDates ||
        oldDelegate.todayStr != todayStr ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.spacing != spacing;
  }
}
