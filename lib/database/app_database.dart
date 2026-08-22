import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// SQLite schema definition for Tasks table.
///
/// 🧠 LEARN: Sync metadata columns enable the "outbox pattern":
/// - [updatedAt]: Tracks the last modification time for sync comparison.
/// - [isDirty]: When true, the row has local changes not yet pushed to Supabase.
/// - [isDeleted]: Soft-delete flag. Instead of removing rows, we mark them deleted
///   so the sync engine can push the deletion to the server before purging locally.
@DataClassName('TaskData')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  // ─── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The local Drift SQLite database entry point.
@DriftDatabase(tables: [Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add the three new sync metadata columns to the existing Tasks table
          await m.addColumn(tasks, tasks.updatedAt);
          await m.addColumn(tasks, tasks.isDirty);
          await m.addColumn(tasks, tasks.isDeleted);
        }
      },
    );
  }
}

/// Helper function to configure the database file storage location.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mindwipe.db'));
    return NativeDatabase.createInBackground(file);
  });
}
