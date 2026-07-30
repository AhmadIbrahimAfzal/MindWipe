import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/widgets/omnitrix_wheel.dart';
import '../providers/inbox_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';

/// The main Inbox screen linked to Riverpod state.
///
/// 🧠 LEARN: By extending [ConsumerStatefulWidget] instead of [StatefulWidget],
/// we get a persistent [ref] object inside our [State] class. This [ref] is used to
/// watch providers (ref.watch) or read them (ref.read).
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  int _currentPageIndex = 0;

  /// Helper to convert a DateTime into a relative string.
  String _getRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Yesterday';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 🧠 LEARN: ref.watch makes this widget listen to the inboxProvider.
    // Every time the list of tasks changes, this build method runs again.
    final tasks = ref.watch(inboxProvider);
    final incompleteCount = tasks.where((t) => !t.isCompleted).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ─── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inbox',
                          style: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$incompleteCount thought${incompleteCount == 1 ? '' : 's'} floating',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    // ─── Profile icon ────────────────────────────────
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.pets_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Task List ───────────────────────────────────
              Expanded(
                child: tasks.isEmpty
                    ? const EmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 16),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          
                          // 🧠 LEARN: Dismissible enables swipe-to-dismiss actions.
                          // It requires a unique key so Flutter can track widget identities.
                          return Dismissible(
                            key: Key(task.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) {
                              // Trigger state deletion
                              ref.read(inboxProvider.notifier).deleteTask(task.id);
                              HapticFeedback.mediumImpact();
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.backgroundElevated,
                                  content: Text(
                                    'Thought cleared',
                                    style: TextStyle(color: AppColors.textPrimary),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 32),
                              color: Colors.transparent,
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error.withValues(alpha: 0.8),
                                size: 24,
                              ),
                            ),
                            child: TaskCard(
                              title: task.title,
                              timestamp: _getRelativeTime(task.createdAt),
                              isCompleted: task.isCompleted,
                              onCompleteTap: () {
                                ref.read(inboxProvider.notifier).toggleComplete(task.id);
                                HapticFeedback.selectionClick();
                              },
                            )
                            .animate(
                              // Apply soft entrance animation to new cards
                              effects: [
                                const FadeEffect(duration: Duration(milliseconds: 300)),
                                const SlideEffect(
                                  begin: Offset(0.05, 0),
                                  curve: Curves.easeOutCubic,
                                  duration: Duration(milliseconds: 350),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // ─── Bottom Wheel (Habits / + / Mind) ────────────
              BottomWheel(
                currentIndex: _currentPageIndex,
                onTaskAdded: (title) {
                  // 🧠 LEARN: ref.read is used inside event handlers
                  // to call methods on the provider notifier.
                  ref.read(inboxProvider.notifier).addTask(title);
                },
                onHabitsTap: () {
                  setState(() => _currentPageIndex = 1);
                  // TODO: Phase 4 — navigate to Habits screen
                },
                onMindTap: () {
                  setState(() => _currentPageIndex = 2);
                  // TODO: Phase 4 — navigate to Mind screen
                },
              ),

              SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ),
    );
  }
}
