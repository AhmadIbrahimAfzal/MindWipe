import 'dart:async';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindwipe/database/app_database.dart';

/// Background sync engine implementing the Outbox Pattern.
///
/// 🧠 LEARN: The Outbox Pattern ensures offline-first reliability:
/// 1. All writes go to local Drift first (with isDirty = true).
/// 2. This service periodically pushes dirty rows to Supabase.
/// 3. It pulls remote changes that are newer than our last sync.
/// 4. Real-time subscriptions give us instant remote updates.
///
/// The UI NEVER waits for a network request. It reads from Drift only.
class SyncService {
  SyncService(this._db);

  final AppDatabase _db;
  static const _lastSyncKey = 'mindwipe_last_sync_timestamp';
  RealtimeChannel? _channel;

  static const _premiumKey = 'mindwipe_is_premium';

  /// Returns true if the user has an active MindWipe Pro subscription.
  Future<bool> _isPro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  /// Start listening for real-time remote changes (Pro feature).
  Future<void> startRealtimeSubscription() async {
    if (!await _isPro()) return;

    final supabase = Supabase.instance.client;
    _channel = supabase
        .channel('tasks-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tasks',
          callback: (payload) async {
            await _handleRealtimeEvent(payload);
          },
        )
        .subscribe();
  }

  /// Stop real-time subscription.
  void stopRealtimeSubscription() {
    _channel?.unsubscribe();
    _channel = null;
  }

  /// Full sync cycle: push local changes, then pull remote changes (Pro feature).
  Future<void> sync() async {
    // Paywall check: Free tier data stays strictly on the local device
    if (!await _isPro()) return;

    try {
      await pushDirtyRows();
      await pullRemoteChanges();
    } catch (e) {
      // Sync failures are non-fatal — we're offline-first.
      // The next sync cycle will retry.
    }
  }

  // ─── PUSH: Local → Supabase ──────────────────────────────────

  /// Pushes all locally dirty rows to Supabase.
  ///
  /// 🧠 LEARN: We use Supabase's `upsert` to insert-or-update.
  /// Crucially, we verify the server echoes the row back.
  /// Under RLS, a rejected write returns success with zero rows —
  /// so we only clear isDirty if the server actually returns data.
  Future<void> pushDirtyRows() async {
    final supabase = Supabase.instance.client;

    // Query all dirty rows from local Drift
    final dirtyRows = await (_db.select(_db.tasks)
          ..where((t) => t.isDirty.equals(true)))
        .get();

    for (final row in dirtyRows) {
      try {
        if (row.isDeleted) {
          // Push deletion to Supabase
          await supabase.from('tasks').delete().eq('id', row.id);
          // Purge from local DB after confirmed server deletion
          await (_db.delete(_db.tasks)..where((t) => t.id.equals(row.id))).go();
        } else {
          // Upsert to Supabase and verify the echo
          final response = await supabase.from('tasks').upsert({
            'id': row.id,
            'title': row.title,
            'created_at': row.createdAt.toIso8601String(),
            'is_completed': row.isCompleted,
            'completed_at': row.completedAt?.toIso8601String(),
            'updated_at': row.updatedAt.toIso8601String(),
          }).select();

          // Only clear dirty flag if the server echoed the row back
          if (response.isNotEmpty) {
            await (_db.update(_db.tasks)..where((t) => t.id.equals(row.id)))
                .write(const TasksCompanion(isDirty: Value(false)));
          }
        }
      } catch (_) {
        // Individual row failure — skip and retry on next sync cycle
        continue;
      }
    }
  }

  // ─── PULL: Supabase → Local ──────────────────────────────────

  /// Pulls remote changes newer than our last sync timestamp.
  Future<void> pullRemoteChanges() async {
    final supabase = Supabase.instance.client;
    final prefs = await SharedPreferences.getInstance();
    final lastSyncIso = prefs.getString(_lastSyncKey);
    final lastSync = lastSyncIso != null
        ? DateTime.parse(lastSyncIso)
        : DateTime.fromMillisecondsSinceEpoch(0);

    // Fetch rows updated after our last sync
    final remoteRows = await supabase
        .from('tasks')
        .select()
        .gt('updated_at', lastSync.toIso8601String())
        .order('updated_at');

    for (final row in remoteRows) {
      await _upsertLocalFromRemote(row);
    }

    // Update last sync timestamp
    await prefs.setString(_lastSyncKey, DateTime.now().toUtc().toIso8601String());
  }

  // ─── Real-Time Event Handler ─────────────────────────────────

  Future<void> _handleRealtimeEvent(PostgresChangePayload payload) async {
    final newRecord = payload.newRecord;
    if (newRecord.isEmpty) return;
    await _upsertLocalFromRemote(newRecord);
  }

  /// Inserts or updates a local Drift row from a remote Supabase record.
  /// Does NOT mark the row as dirty (it came from the server).
  Future<void> _upsertLocalFromRemote(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    final remoteUpdatedAt = DateTime.parse(row['updated_at'] as String);

    // Check if we have a local version that's newer (local wins on conflict)
    final localRow = await (_db.select(_db.tasks)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (localRow != null && localRow.isDirty) {
      // Local has unsaved changes — don't overwrite with older remote data
      if (localRow.updatedAt.isAfter(remoteUpdatedAt)) return;
    }

    final completedAtStr = row['completed_at'] as String?;

    await _db.into(_db.tasks).insertOnConflictUpdate(
      TaskData(
        id: id,
        title: row['title'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        isCompleted: row['is_completed'] as bool? ?? false,
        completedAt: completedAtStr != null ? DateTime.parse(completedAtStr) : null,
        updatedAt: remoteUpdatedAt,
        isDirty: false,
        isDeleted: false,
      ),
    );
  }
}
