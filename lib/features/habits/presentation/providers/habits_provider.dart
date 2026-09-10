import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindwipe/core/services/audio_service.dart';
import 'package:mindwipe/features/inbox/presentation/providers/inbox_provider.dart';
import 'package:mindwipe/features/habits/data/datasources/habit_local_datasource.dart';
import 'package:mindwipe/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:mindwipe/features/habits/domain/entities/habit.dart';
import 'package:mindwipe/features/habits/domain/repositories/habit_repository.dart';
import 'package:mindwipe/features/widget_bridge/widget_sync_service.dart';

final habitLocalDatasourceProvider = Provider<HabitLocalDatasource>((ref) {
  final db = ref.watch(databaseProvider);
  return HabitLocalDatasource(db);
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final datasource = ref.watch(habitLocalDatasourceProvider);
  return HabitRepositoryImpl(datasource);
});

class HabitsNotifier extends StreamNotifier<List<Habit>> {
  @override
  Stream<List<Habit>> build() {
    final repo = ref.watch(habitRepositoryProvider);
    // Convert to broadcast so both Riverpod AND widget sync can listen
    final stream = repo.watchHabits().asBroadcastStream();

    // Broadcast update to Android home screen habit widget
    final sub = stream.listen((habits) {
      const WidgetSyncService().updateHabitWidget(habits);
    });
    ref.onDispose(() => sub.cancel());

    return stream;
  }

  /// Create a new habit.
  Future<void> createHabit({
    required String name,
    required String description,
    required String iconKey,
    required int colorValue,
    required String habitType,
  }) async {
    await ref.read(habitRepositoryProvider).createHabit(
          name: name,
          description: description,
          iconKey: iconKey,
          colorValue: colorValue,
          habitType: habitType,
        );
    AudioFeedback.playPop();
  }

  /// Update an existing habit.
  Future<void> updateHabit(Habit habit) async {
    await ref.read(habitRepositoryProvider).updateHabit(habit);
    AudioFeedback.playPop();
  }

  /// Delete a habit.
  Future<void> deleteHabit(String id) async {
    await ref.read(habitRepositoryProvider).deleteHabit(id);
    AudioFeedback.playWhoosh();
  }

  /// Toggle completion on today.
  Future<void> toggleToday(String habitId) async {
    final habits = state.value ?? [];
    final habit = habits.firstWhere((h) => h.id == habitId, orElse: () => habits.first);
    final isAlreadyCompleted = habit.isCompletedToday();

    await ref.read(habitRepositoryProvider).toggleToday(habitId);

    if (!isAlreadyCompleted) {
      AudioFeedback.playPop();
    } else {
      AudioFeedback.playTick();
    }
  }

  /// Toggle completion on a specific past date.
  Future<void> toggleDate(String habitId, String dateStr) async {
    await ref.read(habitRepositoryProvider).toggleDate(habitId, dateStr);
    AudioFeedback.playTick();
  }

  /// Forces the stream to re-query SQLite, picking up external writes
  /// (e.g. habit toggles from the Android Home Screen widget).
  void refresh() {
    ref.read(databaseProvider).notifyExternalUpdate();
    ref.invalidateSelf();
  }
}

final habitsProvider = StreamNotifierProvider<HabitsNotifier, List<Habit>>(() {
  return HabitsNotifier();
});
