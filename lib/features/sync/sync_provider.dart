import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindwipe/features/inbox/presentation/providers/inbox_provider.dart';
import 'package:mindwipe/features/sync/sync_service.dart';

/// Exposes the [SyncService] singleton via Riverpod.
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final service = SyncService(db);
  ref.onDispose(() => service.stopRealtimeSubscription());
  return service;
});
