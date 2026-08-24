import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindwipe/features/widget_bridge/widget_sync_service.dart';
import 'package:mindwipe/features/inbox/presentation/providers/inbox_provider.dart';

/// Subscription state model.
///
/// 🧠 LEARN:
/// - [isPremium]: Controls paywalled features (Cloud Sync to Supabase, All Android Widgets).
/// - Free tier: 100% offline-first local SQLite, only the Brain Dump Bar widget.
/// - Pro tier: Cloud backup, multi-device sync, all home screen widgets, AI analytics.
class SubscriptionState {
  const SubscriptionState({
    required this.isPremium,
    this.planName = 'MindWipe Free',
  });

  final bool isPremium;
  final String planName;

  SubscriptionState copyWith({
    bool? isPremium,
    String? planName,
  }) {
    return SubscriptionState(
      isPremium: isPremium ?? this.isPremium,
      planName: planName ?? this.planName,
    );
  }
}

/// Manages subscription tier & persistence.
class SubscriptionNotifier extends Notifier<SubscriptionState> {
  static const _prefKey = 'mindwipe_is_premium';

  @override
  SubscriptionState build() {
    _loadFromPrefs();
    return const SubscriptionState(isPremium: false, planName: 'MindWipe Free');
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_prefKey) ?? false;
    state = SubscriptionState(
      isPremium: isPremium,
      planName: isPremium ? 'MindWipe Pro' : 'MindWipe Free',
    );
  }

  /// Upgrades or toggles premium status.
  Future<void> setPremium(bool isPremium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isPremium);
    state = SubscriptionState(
      isPremium: isPremium,
      planName: isPremium ? 'MindWipe Pro' : 'MindWipe Free',
    );

    // Sync updated status to native Android widgets
    final tasks = await ref.read(taskRepositoryProvider).getTasks();
    await const WidgetSyncService().updateWidgets(tasks, isPremium: isPremium);
  }

  Future<void> unlockPro() async {
    await setPremium(true);
  }

  Future<void> downgradeToFree() async {
    await setPremium(false);
  }
}

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, SubscriptionState>(() {
  return SubscriptionNotifier();
});
