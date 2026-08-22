import 'dart:async';
import 'package:mindwipe/features/inbox/data/datasources/task_local_datasource.dart';
import 'package:mindwipe/features/inbox/data/models/task_model.dart';
import 'package:mindwipe/features/inbox/domain/entities/task.dart';
import 'package:mindwipe/features/inbox/domain/repositories/task_repository.dart';

/// Concrete implementation of the TaskRepository contract.
///
/// 🧠 LEARN: deleteTask now uses soft-deletion (marks isDeleted = true)
/// instead of physically removing rows. The sync engine will push the
/// deletion to Supabase and then purge the row locally.
class TaskRepositoryImpl implements TaskRepository {
  const TaskRepositoryImpl(this._localDatasource);

  final TaskLocalDatasource _localDatasource;

  @override
  Future<List<Task>> getTasks() async {
    final tasksList = await _localDatasource.watchTasks().first;
    return tasksList.map((t) => t.toEntity()).toList();
  }

  @override
  Stream<List<Task>> watchTasks() {
    return _localDatasource.watchTasks().map(
          (list) => list.map((t) => t.toEntity()).toList(),
        );
  }

  @override
  Future<void> saveTask(Task task) async {
    await _localDatasource.insertTask(task.toData());
  }

  @override
  Future<void> updateTask(Task task) async {
    await _localDatasource.updateTask(task.toData());
  }

  @override
  Future<void> deleteTask(String id) async {
    // Soft-delete for sync safety
    await _localDatasource.softDeleteTask(id);
  }
}
