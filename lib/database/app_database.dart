import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// SQLite schema definition for Tasks table.
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

/// SQLite schema definition for Habits table.
@DataClassName('HabitData')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get iconKey => text().withDefault(const Constant('sport'))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF6366F1))();
  TextColumn get habitType => text().withDefault(const Constant('build'))(); // 'build' or 'quit'
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  // ─── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// SQLite schema definition for daily habit completions.
@DataClassName('HabitCompletionData')
class HabitCompletions extends Table {
  TextColumn get id => text()(); // Format: '${habitId}_${date}'
  TextColumn get habitId => text().references(Habits, #id)();
  TextColumn get date => text()(); // Format: 'YYYY-MM-DD'
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  // ─── Sync Metadata ─────────────────────────────────────────────
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The local Drift SQLite database entry point.
@DriftDatabase(tables: [Tasks, Habits, HabitCompletions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(tasks, tasks.updatedAt);
          await m.addColumn(tasks, tasks.isDirty);
          await m.addColumn(tasks, tasks.isDeleted);
        }
        if (from < 3) {
          await m.createTable(habits);
          await m.createTable(habitCompletions);
        }
      },
    );
  }

  /// Explicitly notifies Drift stream queries that external SQLite writes have occurred
  /// (e.g. from the Android QuickCapture activity or native Home Screen widgets).
  void notifyExternalUpdate() {
    notifyUpdates({
      TableUpdate.onTable(tasks),
      TableUpdate.onTable(habits),
      TableUpdate.onTable(habitCompletions),
    });
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
