import 'package:drift/drift.dart';
import 'package:mindwipe/database/app_database.dart';

class HabitWithCompletionsData {
  HabitWithCompletionsData({
    required this.habit,
    required this.completedDates,
  });

  final HabitData habit;
  final Set<String> completedDates;
}

class HabitLocalDatasource {
  const HabitLocalDatasource(this._db);

  final AppDatabase _db;

  /// Watch all active (non-deleted) habits with their completed dates.
  Stream<List<HabitWithCompletionsData>> watchHabits() {
    final habitsQuery = _db.select(_db.habits)
      ..where((h) => h.isDeleted.equals(false))
      ..orderBy([(h) => OrderingTerm(expression: h.orderIndex)]);

    return habitsQuery.watch().asyncMap((habits) async {
      if (habits.isEmpty) return [];

      final completions = await (_db.select(_db.habitCompletions)
            ..where((c) => c.isDeleted.equals(false)))
          .get();

      final completionMap = <String, Set<String>>{};
      for (final c in completions) {
        completionMap.putIfAbsent(c.habitId, () => <String>{}).add(c.date);
      }

      return habits.map((habit) {
        return HabitWithCompletionsData(
          habit: habit,
          completedDates: completionMap[habit.id] ?? <String>{},
        );
      }).toList();
    });
  }

  /// Insert a new habit.
  Future<void> insertHabit(HabitsCompanion habit) async {
    await _db.into(_db.habits).insert(habit);
  }

  /// Update an existing habit.
  Future<void> updateHabit(HabitsCompanion habit) async {
    await (_db.update(_db.habits)..where((h) => h.id.equals(habit.id.value)))
        .write(habit);
  }

  /// Soft delete a habit.
  Future<void> softDeleteHabit(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        isDeleted: const Value(true),
        isDirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  /// Toggle completion on a date.
  Future<void> toggleDate(String habitId, String dateStr) async {
    final id = '${habitId}_$dateStr';
    final existing = await (_db.select(_db.habitCompletions)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();

    final now = DateTime.now();

    if (existing != null) {
      if (existing.isDeleted) {
        // Un-delete / re-complete
        await (_db.update(_db.habitCompletions)..where((c) => c.id.equals(id)))
            .write(
          HabitCompletionsCompanion(
            isDeleted: const Value(false),
            isDirty: const Value(true),
            completedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      } else {
        // Mark deleted / incomplete
        await (_db.update(_db.habitCompletions)..where((c) => c.id.equals(id)))
            .write(
          HabitCompletionsCompanion(
            isDeleted: const Value(true),
            isDirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
      }
    } else {
      // Insert new completion
      await _db.into(_db.habitCompletions).insert(
            HabitCompletionsCompanion.insert(
              id: id,
              habitId: habitId,
              date: dateStr,
              completedAt: now,
              createdAt: now,
              updatedAt: now,
              isDirty: const Value(true),
              isDeleted: const Value(false),
            ),
          );
    }
  }
}
