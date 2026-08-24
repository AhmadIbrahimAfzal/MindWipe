import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:mindwipe/features/sync/sync_provider.dart';

/// MindWipe Pro Paywall & Subscription Screen.
///
/// 🧠 LEARN:
/// - Paywalls Cloud Sync & Multi-device Backup (free tier is 100% on-device SQLite).
/// - Unlocks all Android Home Screen Widgets (Micro Task Pill, etc).
/// - Dark glassmorphic design matching the app's aesthetic.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlanIndex = 0; // 0: Annual, 1: Monthly, 2: Lifetime

  final List<Map<String, String>> _plans = [
    {
      'title': 'Annual',
      'price': '\$19.99 / year',
      'subtext': '\$1.66/month • 7-day free trial',
      'tag': 'BEST VALUE',
    },
    {
      'title': 'Monthly',
      'price': '\$2.99 / month',
      'subtext': 'Billed monthly • Cancel anytime',
      'tag': '',
    },
    {
      'title': 'Lifetime',
      'price': '\$49.99',
      'subtext': 'One-time payment • Forever access',
      'tag': 'FOREVER',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Header with Close Button ─────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await ref.read(subscriptionProvider.notifier).unlockPro();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Purchases restored ✨')),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                        'Restore',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Content ──────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 12),

                    // Crown / Pro Badge
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.02),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 32,
                          color: AppColors.textPrimary,
                        ),
                      )
                          .animate()
                          .scaleXY(
                            begin: 0.8,
                            end: 1.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                          ),
                    ),

                    const SizedBox(height: 16),

                    // Title & Subtitle
                    Center(
                      child: Text(
                        'MindWipe Pro',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Sync across all your devices & unlock all widgets',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Feature Checklist
                    _buildFeatureRow(
                      icon: Icons.cloud_sync_rounded,
                      title: 'Cloud Backup & Multi-Device Sync',
                      description: 'Real-time sync to all your phones, tablets & devices',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureRow(
                      icon: Icons.widgets_rounded,
                      title: 'All Home Screen Widgets Unlocked',
                      description: 'Floating Micro-Task Pill & upcoming widget styles',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureRow(
                      icon: Icons.psychology_rounded,
                      title: 'Mind AI Insights & Analytics',
                      description: 'AI thought pattern detection & habit stats',
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureRow(
                      icon: Icons.offline_bolt_rounded,
                      title: 'Zero Latency & Priority Sync',
                      description: 'Instant local persistence + high speed cloud replication',
                    ),

                    const SizedBox(height: 28),

                    // Plan Selection Cards
                    ...List.generate(_plans.length, (index) {
                      final plan = _plans[index];
                      final isSelected = _selectedPlanIndex == index;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedPlanIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.backgroundSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.06),
                              width: isSelected ? 1.0 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Radio Indicator
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                    width: 1.5,
                                  ),
                                  color: isSelected
                                      ? AppColors.textPrimary
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: AppColors.backgroundDeep,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 14),

                              // Plan details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          plan['title']!,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (plan['tag']!.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              plan['tag']!,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      plan['subtext']!,
                                      style: TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Price
                              Text(
                                plan['price']!,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Upgrade CTA Button
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await ref.read(subscriptionProvider.notifier).unlockPro();
                        // Trigger immediate sync on unlock
                        ref.read(syncServiceProvider).sync();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Welcome to MindWipe Pro! 🚀'),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            subState.isPremium
                                ? 'Pro Active (Tap to Reactivate)'
                                : 'Start 7-Day Free Trial',
                            style: const TextStyle(
                              color: AppColors.backgroundDeep,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        'Cancel anytime in Google Play Store settings.',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
