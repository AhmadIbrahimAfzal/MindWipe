import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import '../providers/inbox_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';
import 'package:mindwipe/features/auth/presentation/screens/account_screen.dart';

/// The modular Inbox list component linked to local database streams.
///
/// 🧠 LEARN:
/// - [ref.watch(inboxProvider)] now returns an [AsyncValue<List<Task>>] because
///   it watches a database [Stream].
/// - We use `tasksAsync.when` to handle the three states: data, loading, and error.
/// - This ensures the app doesn't crash or show empty lists while SQLite loads.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
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

    // Watch the database async stream
    final tasksAsync = ref.watch(inboxProvider);

    return Column(
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
                  // Render pending count based on loaded stream state
                  tasksAsync.when(
                    data: (tasks) {
                      final incompleteCount = tasks.where((t) => !t.isCompleted).length;
                      return Text(
                        '$incompleteCount thought${incompleteCount == 1 ? '' : 's'} floating',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      );
                    },
                    loading: () => Text(
                      'Loading thoughts...',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    error: (_, __) => Text(
                      'Error loading thoughts',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              // ─── Profile icon ───
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountScreen(),
                    ),
                  );
                },
                child: Container(
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
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ─── Task List ───────────────────────────────────
        Expanded(
          child: tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return const EmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Dismissible(
                    key: Key(task.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
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
                    ).animate(
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
              );
            },
            // Loading and error states
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
              ),
            ),
            error: (error, _) => Center(
              child: Text(
                'Failed to load thoughts: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
