import 'package:mindwipe/features/habits/domain/entities/habit.dart';

abstract class HabitRepository {
  /// Stream of all active habits with their completion history.
  Stream<List<Habit>> watchHabits();

  /// Fetch all active habits once.
  Future<List<Habit>> getHabits();

  /// Create a new habit.
  Future<void> createHabit({
    required String name,
    required String description,
    required String iconKey,
    required int colorValue,
    required String habitType,
  });

  /// Update an existing habit.
  Future<void> updateHabit(Habit habit);

  /// Soft-delete a habit.
  Future<void> deleteHabit(String id);

  /// Toggle completion on a specific 'YYYY-MM-DD' date string.
  Future<void> toggleDate(String habitId, String dateStr);

  /// Toggle completion for today.
  Future<void> toggleToday(String habitId);
}
