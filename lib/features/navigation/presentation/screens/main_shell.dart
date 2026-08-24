import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/widgets/fluid_bottom_nav.dart';
import 'package:mindwipe/features/inbox/presentation/screens/inbox_screen.dart';
import 'package:mindwipe/features/inbox/presentation/providers/inbox_provider.dart';
import 'package:mindwipe/features/habits/presentation/screens/habits_screen.dart';
import 'package:mindwipe/features/mind/presentation/screens/mind_screen.dart';
import 'package:mindwipe/features/habits/presentation/providers/habits_provider.dart';
import 'package:mindwipe/features/auth/presentation/providers/auth_provider.dart';
import 'package:mindwipe/features/sync/sync_provider.dart';

/// The root layout manager shell.
///
/// Coordinates the PageView hosting 3 sub-screens (Habits, Inbox, Mind),
/// synchronizes the FluidBottomNav with the PageController,
/// and initializes background auth/sync services on launch.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);

    // Initialize guest session, background sync, and warm up habit widget sync
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authProvider.notifier).ensureSession();
      final syncService = ref.read(syncServiceProvider);
      syncService.startRealtimeSubscription();
      syncService.sync();
      // Eagerly listen to habits to sync home screen widget
      ref.read(habitsProvider);
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
        decoration: const BoxDecoration(
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
                padding: const EdgeInsets.only(bottom: 110),
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

              // ─── Fluid Bottom Navigation Bar ──────────────────
              Positioned(
                bottom: bottomPadding,
                left: 0,
                right: 0,
                child: FluidBottomNav(
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
