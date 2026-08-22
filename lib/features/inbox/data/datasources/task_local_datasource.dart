import 'package:drift/drift.dart';
import 'package:mindwipe/database/app_database.dart';

/// Concrete local database datasource using Drift.
///
/// 🧠 LEARN: The watch query now filters out soft-deleted tasks
/// (isDeleted == false) so the UI never shows "deleted" rows.
/// The sync engine will handle purging them after pushing the deletion.
class TaskLocalDatasource {
  const TaskLocalDatasource(this._db);

  final AppDatabase _db;

  /// Watch all non-deleted tasks ordered by creation time descending.
  Stream<List<TaskData>> watchTasks() {
    return (_db.select(_db.tasks)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Add a task to the local database.
  Future<void> insertTask(TaskData task) async {
    await _db.into(_db.tasks).insert(task);
  }

  /// Update an existing task row (marks it dirty).
  Future<void> updateTask(TaskData task) async {
    await _db.update(_db.tasks).replace(task);
  }

  /// Soft-delete a task: marks it as deleted and dirty for sync.
  Future<void> softDeleteTask(String id) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isDeleted: const Value(true),
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
