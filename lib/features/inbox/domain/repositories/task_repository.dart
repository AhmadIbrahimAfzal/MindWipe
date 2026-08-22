import '../entities/task.dart';

/// Abstract interface contract defining the CRUD methods for tasks.
///
/// 🧠 LEARN: The presentation layer only relies on this abstract contract,
/// not any specific database code. This allows us to swap databases (Drift, Hive, Firebase)
/// without changing a single line of presentation code.
abstract class TaskRepository {
  Future<List<Task>> getTasks();
  Stream<List<Task>> watchTasks();
  Future<void> saveTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
}
