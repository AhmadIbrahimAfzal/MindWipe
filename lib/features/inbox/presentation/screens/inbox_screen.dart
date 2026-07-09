import 'package:flutter/material.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import '../widgets/task_card.dart';
import '../widgets/quick_add_bar.dart';
import '../widgets/empty_state.dart';

/// The main Inbox screen — the heart of MindWipe.
///
/// 🧠 LEARN: This is a [StatefulWidget] because it manages the scroll
/// position and will later manage task interactions. The [State] object
/// persists across rebuilds (e.g., when hot-reloading).
///
/// STRUCTURE:
/// - A gradient background fills the entire screen
/// - A scrollable list of TaskCards floats in the center
/// - A QuickAddBar is pinned to the bottom
/// - When empty, the EmptyState widget shows
///
/// In Phase 2, we'll replace the hardcoded tasks with real state management.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  // Hardcoded sample tasks for Phase 1 (static UI)
  // In Phase 2, these will come from Riverpod state
  final List<Map<String, dynamic>> _sampleTasks = [
    {
      'title': 'Order 20mm metal Casio spring bars',
      'timestamp': '2 min ago',
      'isCompleted': false,
    },
    {
      'title': 'Pack trekking gear for Fairy Meadows',
      'timestamp': '15 min ago',
      'isCompleted': false,
    },
    {
      'title': 'Research MVVM architecture for Flutter',
      'timestamp': '1 hour ago',
      'isCompleted': true,
    },
    {
      'title': 'Hit 100g protein target',
      'timestamp': '3 hours ago',
      'isCompleted': false,
    },
    {
      'title': 'Take Creatine',
      'timestamp': '5 hours ago',
      'isCompleted': true,
    },
    {
      'title': 'Chest & Triceps split — 5 exercises',
      'timestamp': 'Yesterday',
      'isCompleted': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Get the bottom padding for devices with gesture navigation
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // Transparent scaffold — we draw our own background
      backgroundColor: Colors.transparent,
      body: Container(
        // ─── Full-screen gradient background ──────────────────
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          bottom: false, // We handle bottom padding manually
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inbox',
                      style: textTheme.displayMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_sampleTasks.where((t) => !(t['isCompleted'] as bool)).length} thoughts floating',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ─── Task List ───────────────────────────────────
              Expanded(
                child: _sampleTasks.isEmpty
                    ? const EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _sampleTasks.length,
                        itemBuilder: (context, index) {
                          final task = _sampleTasks[index];
                          return TaskCard(
                            title: task['title'] as String,
                            timestamp: task['timestamp'] as String,
                            isCompleted: task['isCompleted'] as bool,
                            onCompleteTap: () {
                              setState(() {
                                task['isCompleted'] = !(task['isCompleted'] as bool);
                              });
                            },
                          );
                        },
                      ),
              ),

              // ─── Quick Add Bar (pinned to bottom) ────────────
              Padding(
                padding: EdgeInsets.only(bottom: bottomPadding + 8),
                child: const QuickAddBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
