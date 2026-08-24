/// Habit domain entity representing a tracked ritual.
class Habit {
  const Habit({
    required this.id,
    required this.name,
    this.description = '',
    this.iconKey = 'sport',
    this.colorValue = 0xFF6366F1,
    this.habitType = 'build', // 'build' or 'quit'
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.completedDates = const {}, // Set of 'YYYY-MM-DD' strings
  });

  final String id;
  final String name;
  final String description;
  final String iconKey;
  final int colorValue;
  final String habitType;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Set<String> completedDates;

  /// Returns true if completed on a specific 'YYYY-MM-DD' date string.
  bool isCompletedOn(String dateStr) => completedDates.contains(dateStr);

  /// Returns true if completed today.
  bool isCompletedToday([DateTime? now]) {
    final current = now ?? DateTime.now();
    final todayStr = _formatDate(current);
    return completedDates.contains(todayStr);
  }

  /// Calculates the current active streak in consecutive days.
  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    int streak = 0;
    DateTime checkDate = DateTime.now();

    // If not completed today, check from yesterday
    final todayStr = _formatDate(checkDate);
    if (!completedDates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (completedDates.contains(_formatDate(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Total count of completions.
  int get totalCompletions => completedDates.length;

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? iconKey,
    int? colorValue,
    String? habitType,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    Set<String>? completedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      habitType: habitType ?? this.habitType,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  static String _formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
