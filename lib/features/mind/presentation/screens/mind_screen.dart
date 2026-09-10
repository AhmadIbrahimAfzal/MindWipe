import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindwipe/core/theme/app_colors.dart';

/// MindMap teaser screen — premium AI-powered context mapping (coming soon).
///
/// Builds anticipation with:
/// - Animated constellation hero graphic
/// - Feature preview pills
/// - PRO badge
/// - "Notify Me" email waitlist CTA
class MindScreen extends StatefulWidget {
  const MindScreen({super.key});

  @override
  State<MindScreen> createState() => _MindScreenState();
}

class _MindScreenState extends State<MindScreen> with AutomaticKeepAliveClientMixin {
  bool _hasJoinedWaitlist = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkWaitlistStatus();
  }

  Future<void> _checkWaitlistStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hasJoinedWaitlist = prefs.getBool('mindmap_waitlist_joined') ?? false;
      });
    }
  }

  void _showNotifyMeSheet() {
    final emailController = TextEditingController();
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 40,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Get Early Access',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Be the first to try MindMap',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Email input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textTertiary,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.mail_outline_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty || !email.contains('@')) {
                      return;
                    }
                    HapticFeedback.mediumImpact();
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('mindmap_waitlist_joined', true);
                    await prefs.setString('mindmap_waitlist_email', email);

                    if (mounted) {
                      setState(() => _hasJoinedWaitlist = true);
                      navigator.pop();
                      messenger.clearSnackBars();
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.only(
                            bottom: 140, left: 24, right: 24,
                          ),
                          padding: EdgeInsets.zero,
                          duration: const Duration(seconds: 3),
                          content: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSurface
                                  .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Text(
                                  "You'll be first to know!",
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Notify Me',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MindMap',
                      style: textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI-Powered Context Mapping',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // PRO Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Text(
                  'PRO',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Body ─────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ─── Constellation Hero Graphic ───────────────
                _buildConstellationHero(),

                const SizedBox(height: 32),

                // ─── Description ──────────────────────────────
                Text(
                  'Save screenshots, text & ideas — AI automatically groups them into a navigable visual map.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 600),
                    ),

                const SizedBox(height: 28),

                // ─── Feature Preview Pills ────────────────────
                _buildFeaturePill(
                  icon: Icons.camera_alt_rounded,
                  label: 'Screenshot Capture',
                  delay: 300,
                ),
                const SizedBox(height: 10),
                _buildFeaturePill(
                  icon: Icons.psychology_rounded,
                  label: 'AI Categorization',
                  delay: 450,
                ),
                const SizedBox(height: 10),
                _buildFeaturePill(
                  icon: Icons.hub_rounded,
                  label: 'Visual Context Map',
                  delay: 600,
                ),

                const SizedBox(height: 36),

                // ─── CTA Button ───────────────────────────────
                _hasJoinedWaitlist
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "You're on the waitlist!",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                        .animate()
                        .fadeIn(duration: const Duration(milliseconds: 400))
                    : SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _showNotifyMeSheet,
                          icon: const Icon(
                            Icons.notifications_active_rounded,
                            size: 20,
                          ),
                          label: Text(
                            'Notify Me When Ready',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      )
                        .animate()
                        .fadeIn(
                          delay: const Duration(milliseconds: 750),
                          duration: const Duration(milliseconds: 500),
                        )
                        .slideY(
                          begin: 0.1,
                          end: 0,
                          delay: const Duration(milliseconds: 750),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                        ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Animated constellation/network graphic with floating orbs and connections.
  Widget _buildConstellationHero() {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 0.95,
                end: 1.08,
                duration: const Duration(milliseconds: 3200),
                curve: Curves.easeInOut,
              ),

          // Middle ring
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.8,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.05,
                duration: const Duration(milliseconds: 2600),
                curve: Curves.easeInOut,
              ),

          // Center hub icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.hub_rounded,
              size: 28,
              color: Colors.white,
            ),
          )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 600))
              .scaleXY(
                begin: 0.7,
                end: 1.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              ),

          // Orbiting dots
          ..._buildOrbitDots(),
        ],
      ),
    );
  }

  List<Widget> _buildOrbitDots() {
    final dots = <_OrbitDot>[
      _OrbitDot(offset: const Offset(-54, -40), size: 10, delay: 100, color: const Color(0xFFAAAAAA)),
      _OrbitDot(offset: const Offset(58, -30), size: 8, delay: 250, color: const Color(0xFFCCCCCC)),
      _OrbitDot(offset: const Offset(-48, 42), size: 9, delay: 400, color: const Color(0xFF999999)),
      _OrbitDot(offset: const Offset(50, 48), size: 7, delay: 550, color: const Color(0xFFBBBBBB)),
      _OrbitDot(offset: const Offset(0, -58), size: 6, delay: 700, color: const Color(0xFFDDDDDD)),
    ];

    return dots.map((dot) {
      return Positioned(
        left: 80 + dot.offset.dx - dot.size / 2,
        top: 80 + dot.offset.dy - dot.size / 2,
        child: Container(
          width: dot.size,
          height: dot.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dot.color.withValues(alpha: 0.7),
          ),
        )
            .animate(
              delay: Duration(milliseconds: dot.delay),
            )
            .fadeIn(duration: const Duration(milliseconds: 500))
            .then()
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -3,
              end: 3,
              duration: Duration(milliseconds: 1800 + dot.delay),
              curve: Curves.easeInOut,
            ),
      );
    }).toList();
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String label,
    required int delay,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: const Duration(milliseconds: 450),
        )
        .slideX(
          begin: 0.05,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
  }
}

class _OrbitDot {
  final Offset offset;
  final double size;
  final int delay;
  final Color color;

  const _OrbitDot({
    required this.offset,
    required this.size,
    required this.delay,
    required this.color,
  });
}
