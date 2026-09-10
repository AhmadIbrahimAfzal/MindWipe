import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/features/navigation/presentation/screens/main_shell.dart';

/// First-launch onboarding — 3 animated slides introducing MindWipe.
///
/// Stores `has_seen_onboarding = true` in SharedPreferences on completion
/// so the user only sees this once.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      iconColor: Color(0xFFFFD60A),
      glowColor: Color(0xFFFFD60A),
      title: 'Brain Dump Instantly',
      subtitle:
          'Capture thoughts the moment they hit.\nSwipe up, type, done.',
    ),
    _OnboardingSlide(
      icon: Icons.grid_view_rounded,
      iconColor: Color(0xFF32D74B),
      glowColor: Color(0xFF32D74B),
      title: 'Build Rituals That Stick',
      subtitle:
          'Track daily habits with a beautiful\nconsistency grid.',
    ),
    _OnboardingSlide(
      icon: Icons.psychology_rounded,
      iconColor: Color(0xFF8B5CF6),
      glowColor: Color(0xFF8B5CF6),
      title: 'Your Second Brain',
      subtitle:
          'Cloud sync, home screen widgets,\nand AI-powered MindMap coming soon.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const MainShell(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              // ─── Skip Button ──────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _completeOnboarding,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 24, 0),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Page Content ─────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    HapticFeedback.selectionClick();
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _buildSlide(slide, index);
                  },
                ),
              ),

              // ─── Dot Indicator ────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    final isActive = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isActive
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    );
                  }),
                ),
              ),

              // ─── CTA Button ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _currentPage == _slides.length - 1
                        ? ElevatedButton(
                            key: const ValueKey('get_started'),
                            onPressed: _completeOnboarding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textPrimary,
                              foregroundColor: AppColors.backgroundDeep,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Get Started',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            key: const ValueKey('continue'),
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.08),
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color:
                                      Colors.white.withValues(alpha: 0.1),
                                  width: 0.5,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // ─── Icon Circle ──────────────────────────────
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(
              slide.icon,
              size: 42,
              color: slide.iconColor,
            ),
          )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 500))
              .scaleXY(
                begin: 0.7,
                end: 1.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 40),

          // ─── Title ────────────────────────────────────
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 150),
                duration: const Duration(milliseconds: 500),
              )
              .slideY(
                begin: 0.15,
                end: 0,
                delay: const Duration(milliseconds: 150),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 16),

          // ─── Subtitle ─────────────────────────────────
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
              letterSpacing: 0.1,
            ),
          )
              .animate()
              .fadeIn(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
              ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final Color iconColor;
  final Color glowColor;
  final String title;
  final String subtitle;

  const _OnboardingSlide({
    required this.icon,
    required this.iconColor,
    required this.glowColor,
    required this.title,
    required this.subtitle,
  });
}
