import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/features/auth/presentation/screens/account_screen.dart';
import 'package:mindwipe/features/habits/presentation/providers/habits_provider.dart';
import 'package:mindwipe/features/habits/presentation/widgets/edit_habit_sheet.dart';
import 'package:mindwipe/features/habits/presentation/widgets/habit_card.dart';
import 'package:mindwipe/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:mindwipe/features/subscription/presentation/screens/paywall_screen.dart';

/// Habits screen — HabitKit aesthetic ritual tracker.
///
/// Features:
/// - Top Bar: Settings gear icon (left), Stats (center right), and Purple + Add button (right).
/// - Paywall enforcement: 1 habit for free tier, 5+ unlocked with MindWipe Pro.
/// - Dark glassmorphic HabitCards with glowing dot matrix consistency grids.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  void _onAddHabit(BuildContext context, WidgetRef ref, int currentCount, bool isPremium) {
    HapticFeedback.lightImpact();

    // Paywall gate: 1 habit for free tier, Pro unlocks up to 6 habits
    if (!isPremium && currentCount >= 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const PaywallScreen(),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EditHabitSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final subscription = ref.watch(subscriptionProvider);
    final isPremium = subscription.isPremium;

    return Column(
      children: [
        // ─── Top Header Bar ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Settings Gear Button
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),

              // Title
              Text(
                'Habits',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),

              // Right Action Buttons (Stats + Purple Add Habit Button)
              Row(
                children: [
                  // Pro Badge / Stats Icon
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PaywallScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        isPremium
                            ? Icons.insights_rounded
                            : Icons.workspace_premium_rounded,
                        color: isPremium
                            ? AppColors.textSecondary
                            : const Color(0xFFFFB800),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Grey/Black Add Habit Button
                  GestureDetector(
                    onTap: () {
                      final habits = habitsAsync.value ?? [];
                      _onAddHabit(context, ref, habits.length, isPremium);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ─── Habit Cards List ───────────────────────────────
        Expanded(
          child: habitsAsync.when(
            data: (habits) {
              if (habits.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 30,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No habits yet',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create your first daily ritual to begin tracking consistency.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => _onAddHabit(context, ref, 0, isPremium),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.backgroundDeep,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Create First Habit',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.backgroundDeep,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                physics: const BouncingScrollPhysics(),
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return HabitCard(habit: habit);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
                strokeWidth: 2,
              ),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error loading habits',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
