import 'package:mindwipe/database/app_database.dart';
import '../../domain/entities/task.dart';

/// Extension mappings between Domain Entities and Database Models.
///
/// 🧠 LEARN: The mapper now handles the sync metadata columns.
/// When converting TO a database row, we set isDirty = true and
/// updatedAt = DateTime.now() so the sync engine knows to push it.
extension TaskDataMapper on TaskData {
  /// Converts a database model into a pure domain entity.
  Task toEntity() {
    return Task(
      id: id,
      title: title,
      createdAt: createdAt,
      isCompleted: isCompleted,
      completedAt: completedAt,
    );
  }
}

extension TaskMapper on Task {
  /// Converts a domain entity into a database model for insertion.
  /// Marks the row as dirty so the sync engine pushes it.
  TaskData toData() {
    return TaskData(
      id: id,
      title: title,
      createdAt: createdAt,
      isCompleted: isCompleted,
      completedAt: completedAt,
      updatedAt: DateTime.now().toUtc(),
      isDirty: true,
      isDeleted: false,
    );
  }
}
