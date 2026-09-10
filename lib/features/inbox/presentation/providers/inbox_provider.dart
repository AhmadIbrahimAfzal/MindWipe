import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:mindwipe/database/app_database.dart';
import 'package:mindwipe/features/inbox/data/datasources/task_local_datasource.dart';
import 'package:mindwipe/features/inbox/data/repositories/task_repository_impl.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import 'package:mindwipe/features/widget_bridge/widget_sync_service.dart';

// ─── Core Infrastructure Providers ────────────────────────────────
// 🧠 LEARN: We register singletons for our DB layers. Riverpod caches these
// so the database file is only opened once.

/// Exposes the SQLite database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Clean up database on hot-restart / provider destruction
  ref.onDispose(() => db.close());
  return db;
});

/// Exposes the local database datasource.
final taskLocalDatasourceProvider = Provider<TaskLocalDatasource>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskLocalDatasource(db);
});

/// Exposes the task repository implementation.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final datasource = ref.watch(taskLocalDatasourceProvider);
  return TaskRepositoryImpl(datasource);
});

// ─── Reactive State Provider ─────────────────────────────────────

/// Notifier class that manages database operations.
///
/// 🧠 LEARN:
/// - Instead of storing a mutable list in memory, this notifier extends [StreamNotifier].
/// - In [build()], we return a reactive SQLite stream (`watchTasks()`).
/// - When we call [addTask], [toggleComplete], or [deleteTask], we update the SQLite table directly.
/// - The watch stream detects the SQLite write and automatically emits a new list,
///   updating the UI with zero manually synced lists.
class InboxNotifier extends StreamNotifier<List<Task>> {
  @override
  Stream<List<Task>> build() {
    final stream = ref.watch(taskRepositoryProvider).watchTasks();
    // Update home screen widgets whenever task stream emits new state
    final sub = stream.listen((taskList) {
      const WidgetSyncService().updateWidgets(taskList);
    });
    ref.onDispose(() => sub.cancel());
    return stream;
  }

  /// Adds a new task to the local database.
  Future<void> addTask(String title) async {
    final newTask = Task(
      id: const Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
    );
    await ref.read(taskRepositoryProvider).saveTask(newTask);
  }

  /// Toggles the completion status of a task in the local database.
  Future<void> toggleComplete(String id) async {
    // Read the current list from the active stream state
    final currentTasks = state.value ?? [];
    final taskIndex = currentTasks.indexWhere((t) => t.id == id);
    if (taskIndex != -1) {
      final task = currentTasks[taskIndex];
      final newStatus = !task.isCompleted;
      final updatedTask = task.copyWith(
        isCompleted: newStatus,
        completedAt: newStatus ? DateTime.now() : null,
      );
      await ref.read(taskRepositoryProvider).updateTask(updatedTask);
    }
  }

  /// Deletes a task from the local database.
  Future<void> deleteTask(String id) async {
    await ref.read(taskRepositoryProvider).deleteTask(id);
  }

  /// Forces the stream to re-query SQLite, picking up external writes
  /// (e.g. tasks added via the Android QuickCapture widget).
  void refresh() {
    ref.read(databaseProvider).notifyExternalUpdate();
    ref.invalidateSelf();
  }
}

/// Provider reference for the [InboxNotifier].
final inboxProvider = StreamNotifierProvider<InboxNotifier, List<Task>>(() {
  return InboxNotifier();
});
