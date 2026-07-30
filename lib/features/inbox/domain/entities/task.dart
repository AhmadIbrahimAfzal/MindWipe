/// The pure Dart entity representing a task.
///
/// 🧠 LEARN: In clean architecture, entities are kept as pure Dart objects.
/// They do not depend on databases, UI frameworks, or specific state packages.
/// This makes them extremely easy to test and swap details out later.
///
/// Notice the class properties are all [final] and we use [copyWith] to change state.
/// This is the *immutability pattern* — we never modify an existing task instance,
/// we always return a fresh copy.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final bool isCompleted;
  final DateTime? completedAt;

  /// Creates a new copy of the [Task] with selected fields modified.
  Task copyWith({
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
