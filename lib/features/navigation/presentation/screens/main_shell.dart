import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/widgets/omnitrix_wheel.dart';
import 'package:mindwipe/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:mindwipe/features/inbox/presentation/providers/inbox_provider.dart';
import 'package:mindwipe/features/habits/presentation/screens/habits_screen.dart';
import 'package:mindwipe/features/mind/presentation/screens/mind_screen.dart';

/// The root layout manager shell.
///
/// 🧠 LEARN: This shell coordinates:
/// 1. A central [PageView] that hosts our 3 sub-screens (Habits, Inbox, Mind).
/// 2. A single [PageController] that synchronizes state with the [RotaryOmnitrixWheel].
/// 3. Puts the [RotaryOmnitrixWheel] at the bottom of the screen stacked over the content.
import 'package:mindwipe/features/auth/presentation/providers/auth_provider.dart';
import 'package:mindwipe/features/sync/sync_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // Start on Page 1 (Inbox)
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);

    // Initialize guest session and background sync non-blockingly
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authProvider.notifier).ensureSession();
      final syncService = ref.read(syncServiceProvider);
      syncService.startRealtimeSubscription();
      syncService.sync();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        // Outer dark gradient background matching our black/grey aesthetic
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // ─── Swipeable Screen Views ───────────────────────
              Padding(
                // Leave room at the bottom for the wheel height + padding
                padding: const EdgeInsets.only(bottom: 120),
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    HabitsScreen(),
                    InboxScreen(),
                    MindScreen(),
                  ],
                ),
              ),

              // ─── Synchronized Bottom Dial ─────────────────────
              Positioned(
                bottom: bottomPadding,
                left: 0,
                right: 0,
                child: RotaryOmnitrixWheel(
                  pageController: _pageController,
                  onTaskAdded: (title) {
                    ref.read(inboxProvider.notifier).addTask(title);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
