import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:mindwipe/features/subscription/services/purchase_service.dart';
import 'package:mindwipe/features/sync/sync_provider.dart';

/// MindWipe Pro Paywall & Subscription Screen.
///
/// Features:
/// - Connected to Google Play Billing via `PurchaseService`.
/// - 3 Plans: Annual (7-day trial), Monthly, Lifetime (one-time).
/// - Dynamic prices formatted directly by Google Play currency rates.
/// - Full Restore purchases flow and Google Play policy compliance footer.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlanIndex = 0; // 0: Annual, 1: Monthly, 2: Lifetime
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Hook error listener to display friendly snackbar
    PurchaseService.instance.onError = (message) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF2C2C2E),
          ),
        );
      }
    };
  }

  List<Map<String, String>> _getPlans() {
    final annualPrice = PurchaseService.instance.getPriceFormatted(
      PurchaseService.annualProductId,
      '\$19.99 / year',
    );
    final monthlyPrice = PurchaseService.instance.getPriceFormatted(
      PurchaseService.monthlyProductId,
      '\$2.99 / month',
    );
    final lifetimePrice = PurchaseService.instance.getPriceFormatted(
      PurchaseService.lifetimeProductId,
      '\$49.99',
    );

    return [
      {
        'id': PurchaseService.annualProductId,
        'title': 'Annual',
        'price': annualPrice,
        'subtext': 'Includes 7-day free trial • Best value',
        'tag': 'SAVE 45%',
      },
      {
        'id': PurchaseService.monthlyProductId,
        'title': 'Monthly',
        'price': monthlyPrice,
        'subtext': 'Billed monthly • Cancel anytime',
        'tag': '',
      },
      {
        'id': PurchaseService.lifetimeProductId,
        'title': 'Lifetime',
        'price': lifetimePrice,
        'subtext': 'One-time payment • Forever access',
        'tag': 'FOREVER',
      },
    ];
  }

  Future<void> _onSubscribe() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    final plans = _getPlans();
    final selectedProduct = plans[_selectedPlanIndex]['id']!;

    final initiated = await PurchaseService.instance.buyProduct(selectedProduct);
    if (!initiated && mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRestore() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    await PurchaseService.instance.restorePurchases();

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking active subscriptions on Google Play... ✨'),
          backgroundColor: Color(0xFF2C2C2E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final textTheme = Theme.of(context).textTheme;
    final plans = _getPlans();

    // If purchase completed successfully while on this screen
    ref.listen<SubscriptionState>(subscriptionProvider, (previous, next) {
      if (next.isPremium && !(previous?.isPremium ?? false)) {
        if (mounted) {
          setState(() => _isLoading = false);
          ref.read(syncServiceProvider).sync();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to MindWipe Pro! 🚀'),
              backgroundColor: Color(0xFF8B5CF6),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    });

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
              // ─── Header with Close Button & Restore ───────────
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
                      onPressed: _isLoading ? null : _onRestore,
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
                        'Sync across devices, unlock all widgets & track unlimited rituals',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Feature Comparison List ────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 0.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            icon: Icons.sync_rounded,
                            title: 'Real-Time Cloud Sync',
                            description:
                                'Seamless synchronization across all your Android devices with zero latency.',
                          ),
                          const Divider(
                            color: Colors.white10,
                            height: 24,
                            thickness: 0.5,
                          ),
                          _buildFeatureRow(
                            icon: Icons.widgets_rounded,
                            title: 'All Home Screen Widgets',
                            description:
                                'Brain Dump, Micro Task Pill, and Habit Tracker consistency widgets.',
                          ),
                          const Divider(
                            color: Colors.white10,
                            height: 24,
                            thickness: 0.5,
                          ),
                          _buildFeatureRow(
                            icon: Icons.fitness_center_rounded,
                            title: 'Expanded Ritual Tracking',
                            description:
                                'Track multiple simultaneous habits with HabitKit matrix consistency grids.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Plan Selector Cards ────────────────────
                    ...List.generate(plans.length, (index) {
                      final plan = plans[index];
                      final isSelected = _selectedPlanIndex == index;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedPlanIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : Colors.white.withValues(alpha: 0.06),
                              width: isSelected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Radio circle
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
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

                    // ─── Upgrade CTA Button ─────────────────────
                    GestureDetector(
                      onTap: _isLoading ? null : _onSubscribe,
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
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.backgroundDeep,
                                  ),
                                )
                              : Text(
                                  subState.isPremium
                                      ? 'MindWipe Pro Active'
                                      : (_selectedPlanIndex == 0
                                          ? 'Start 7-Day Free Trial'
                                          : 'Upgrade to MindWipe Pro'),
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

                    const SizedBox(height: 14),

                    // Google Play Compliance Disclaimer
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel subscriptions in Google Play Store settings.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10.5,
                            height: 1.35,
                          ),
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
