import 'dart:async';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:mindwipe/database/app_database.dart';
import 'package:mindwipe/features/habits/data/datasources/habit_local_datasource.dart';
import 'package:mindwipe/features/habits/domain/entities/habit.dart';
import 'package:mindwipe/features/habits/domain/repositories/habit_repository.dart';

class HabitRepositoryImpl implements HabitRepository {
  const HabitRepositoryImpl(this._localDatasource);

  final HabitLocalDatasource _localDatasource;
  static const _uuid = Uuid();

  @override
  Stream<List<Habit>> watchHabits() {
    return _localDatasource.watchHabits().map((list) {
      return list.map((item) {
        return Habit(
          id: item.habit.id,
          name: item.habit.name,
          description: item.habit.description,
          iconKey: item.habit.iconKey,
          colorValue: item.habit.colorValue,
          habitType: item.habit.habitType,
          orderIndex: item.habit.orderIndex,
          createdAt: item.habit.createdAt,
          updatedAt: item.habit.updatedAt,
          completedDates: item.completedDates,
        );
      }).toList();
    });
  }

  @override
  Future<List<Habit>> getHabits() async {
    final list = await watchHabits().first;
    return list;
  }

  @override
  Future<void> createHabit({
    required String name,
    required String description,
    required String iconKey,
    required int colorValue,
    required String habitType,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _localDatasource.insertHabit(
      HabitsCompanion.insert(
        id: id,
        name: name,
        description: Value(description),
        iconKey: Value(iconKey),
        colorValue: Value(colorValue),
        habitType: Value(habitType),
        createdAt: now,
        updatedAt: now,
        isDirty: const Value(true),
        isDeleted: const Value(false),
      ),
    );
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final now = DateTime.now();
    await _localDatasource.updateHabit(
      HabitsCompanion(
        id: Value(habit.id),
        name: Value(habit.name),
        description: Value(habit.description),
        iconKey: Value(habit.iconKey),
        colorValue: Value(habit.colorValue),
        habitType: Value(habit.habitType),
        orderIndex: Value(habit.orderIndex),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _localDatasource.softDeleteHabit(id);
  }

  @override
  Future<void> toggleDate(String habitId, String dateStr) async {
    await _localDatasource.toggleDate(habitId, dateStr);
  }

  @override
  Future<void> toggleToday(String habitId) async {
    final now = DateTime.now();
    final todayStr = _formatDate(now);
    await _localDatasource.toggleDate(habitId, todayStr);
  }

  static String _formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
