import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/services/audio_service.dart';
import 'package:mindwipe/features/auth/presentation/screens/account_screen.dart';
import '../providers/inbox_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/inbox_skeleton.dart';

/// The modular Inbox list component linked to local database streams.
///
/// Phase 6 Upgrades:
/// - Shimmer skeleton loading state instead of spinner.
/// - Staggered entrance animations on task cards.
/// - Glassmorphic floating snackbar on delete.
/// - Smooth page transition to Account screen.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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

  void _showGlassSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 140, left: 24, right: 24),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 2),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textTheme = Theme.of(context).textTheme;
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
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return const AccountScreen();
                      },
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.03, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 350),
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
                    Icons.psychology_rounded,
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
                  return RepaintBoundary(
                    child: Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      dismissThresholds: const {DismissDirection.endToStart: 0.35},
                      movementDuration: const Duration(milliseconds: 250),
                      onDismissed: (_) {
                        ref.read(inboxProvider.notifier).deleteTask(task.id);
                        AudioFeedback.playWhoosh();
                        _showGlassSnackBar(context, 'Thought cleared');
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 32),
                        color: Colors.transparent,
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error.withValues(alpha: 0.7),
                          size: 22,
                        ),
                      ),
                      child: TaskCard(
                        title: task.title,
                        timestamp: _getRelativeTime(task.createdAt),
                        isCompleted: task.isCompleted,
                        onCompleteTap: () {
                          ref.read(inboxProvider.notifier).toggleComplete(task.id);
                          AudioFeedback.playPop();
                        },
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: index.clamp(0, 8) * 50),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                      ).slideX(
                        begin: 0.03,
                        end: 0,
                        delay: Duration(milliseconds: index.clamp(0, 8) * 50),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  );
                },
              );
            },
            // Shimmer skeleton instead of spinner
            loading: () => const InboxSkeleton(),
            error: (error, _) => _buildErrorState(error),
          ),
        ),
      ],
    );
  }

  /// Elegant error state with retry action.
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 28,
                color: AppColors.error.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Could not load your thoughts.\nTry again in a moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
