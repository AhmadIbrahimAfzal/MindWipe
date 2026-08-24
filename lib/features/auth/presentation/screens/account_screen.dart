import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/widgets/glass_card.dart';
import 'package:mindwipe/features/auth/presentation/providers/auth_provider.dart';
import 'package:mindwipe/features/sync/sync_provider.dart';
import 'package:mindwipe/features/subscription/presentation/providers/subscription_provider.dart';
import 'package:mindwipe/features/subscription/presentation/screens/paywall_screen.dart';

/// Account settings screen — upgrade from guest to linked account.
///
/// 🧠 LEARN: This uses our existing dark glassmorphic design language.
/// We reuse [GlassCard] for the cards and [AppColors] for the palette.
/// The neumorphic depth effect is achieved with opposing box shadows
/// on the sign-in buttons.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
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
              // ─── Header with Back ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Account',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── Profile Avatar ───────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundSurface,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                  boxShadow: [
                    // Top-left highlight
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.04),
                      offset: const Offset(-3, -3),
                      blurRadius: 8,
                    ),
                    // Bottom-right depth
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      offset: const Offset(4, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  auth.isAuthenticated
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  size: 28,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // ─── Status Label ─────────────────────────────────
              Text(
                auth.isAuthenticated
                    ? auth.email ?? 'Linked Account'
                    : 'Guest Mode',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.isAuthenticated
                    ? 'Your thoughts are synced'
                    : 'Your thoughts live on this device only',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),

              const SizedBox(height: 36),

              // ─── Content ──────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ─── Pro Subscription Status Card ─────────
                      Consumer(
                        builder: (context, ref, _) {
                          final sub = ref.watch(subscriptionProvider);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PaywallScreen(),
                                ),
                              );
                            },
                            child: GlassCard(
                              padding: const EdgeInsets.all(18),
                              margin: const EdgeInsets.only(bottom: 16),
                              borderRadius: 22,
                              opacity: sub.isPremium ? 0.08 : 0.05,
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.06),
                                    ),
                                    child: Icon(
                                      sub.isPremium
                                          ? Icons.workspace_premium_rounded
                                          : Icons.star_border_rounded,
                                      size: 22,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sub.isPremium
                                              ? 'MindWipe Pro Active'
                                              : 'Upgrade to MindWipe Pro',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          sub.isPremium
                                              ? 'Cloud Sync & All Widgets unlocked'
                                              : 'Unlock Cloud Sync & Floating Widgets',
                                          style: TextStyle(
                                            color: AppColors.textTertiary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: AppColors.textTertiary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (!auth.isAuthenticated) ...[
                        // ─── Upgrade Prompt ─────────────────────
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 20,
                                    color: AppColors.textPrimary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Sync & Backup',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Link an account to sync your thoughts across devices and keep a cloud backup.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ─── Google Sign-In Button ──────────────
                        _buildNeumorphicButton(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Continue with Google',
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ref.read(authProvider.notifier).linkGoogle();
                          },
                        ),
                        const SizedBox(height: 12),

                        // ─── Apple Sign-In Button ───────────────
                        _buildNeumorphicButton(
                          icon: Icons.apple_rounded,
                          label: 'Continue with Apple',
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ref.read(authProvider.notifier).linkApple();
                          },
                        ),
                      ] else ...[
                        // ─── Authenticated: Sync Controls ───────
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              _buildSettingsRow(
                                icon: Icons.sync_rounded,
                                label: 'Sync Now',
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ref.read(syncServiceProvider).sync();
                                },
                              ),
                              Divider(
                                color: Colors.white.withValues(alpha: 0.06),
                                height: 24,
                              ),
                              _buildSettingsRow(
                                icon: Icons.logout_rounded,
                                label: 'Sign Out',
                                isDestructive: true,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  ref.read(authProvider.notifier).signOut();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ─── Device Info ──────────────────────────
                      Center(
                        child: Text(
                          'Session: ${auth.displayId}',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Neumorphic-style sign-in button with opposing shadows.
  Widget _buildNeumorphicButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
          boxShadow: [
            // Top-left highlight — subtle lighter grey
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.03),
              offset: const Offset(-2, -2),
              blurRadius: 6,
            ),
            // Bottom-right depth — darker black
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(3, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDestructive ? AppColors.error : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
