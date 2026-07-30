import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';

/// Notifier class that manages the list of tasks.
///
/// 🧠 LEARN: [Notifier] is the modern Riverpod controller.
/// It holds an immutable [state] object (here, a `List<Task>`).
/// To modify state:
/// - We compute the new list (e.g. adding or removing items).
/// - We assign the new list to [state].
/// - Riverpod detects the change and notifies any listening widgets to rebuild.
class InboxNotifier extends Notifier<List<Task>> {
  @override
  List<Task> build() {
    // Initial sample tasks (static UI fallback)
    return [
      Task(
        id: const Uuid().v4(),
        title: 'Order 20mm metal Casio spring bars',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      Task(
        id: const Uuid().v4(),
        title: 'Pack trekking gear for Fairy Meadows',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      Task(
        id: const Uuid().v4(),
        title: 'Research MVVM architecture for Flutter',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isCompleted: true,
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Task(
        id: const Uuid().v4(),
        title: 'Hit 100g protein target',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Task(
        id: const Uuid().v4(),
        title: 'Take Creatine',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isCompleted: true,
        completedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  /// Adds a new task to the inbox.
  void addTask(String title) {
    final newTask = Task(
      id: const Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
    );

    // Prepend the new task to the top of the list
    state = [newTask, ...state];
  }

  /// Toggles the completion status of a task by its ID.
  void toggleComplete(String id) {
    state = state.map((task) {
      if (task.id == id) {
        final newStatus = !task.isCompleted;
        return task.copyWith(
          isCompleted: newStatus,
          completedAt: newStatus ? DateTime.now() : null,
        );
      }
      return task;
    }).toList();
  }

  /// Deletes a task from the list by its ID.
  void deleteTask(String id) {
    state = state.where((task) => task.id != id).toList();
  }
}

/// Provider reference for the [InboxNotifier] to expose its state.
final inboxProvider = NotifierProvider<InboxNotifier, List<Task>>(() {
  return InboxNotifier();
});
