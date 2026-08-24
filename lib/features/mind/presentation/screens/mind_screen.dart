import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindwipe/core/theme/app_colors.dart';

/// Mind screen — Coming Soon placeholder.
///
/// Greyed-out screen with a subtle breathing animation to indicate
/// mind analytics and dump tools are in development.
class MindScreen extends StatelessWidget {
  const MindScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (greyed)
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mind',
                style: textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.0,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mind dump statistics & tools',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Coming Soon Center
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Breathing icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.02),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.04),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      size: 28,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                  )
                      .animate(
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .scaleXY(
                        begin: 1.0,
                        end: 1.06,
                        duration: const Duration(milliseconds: 2800),
                        curve: Curves.easeInOut,
                      ),

                  const SizedBox(height: 24),

                  Text(
                    'Coming Soon',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.3,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 150),
                        duration: const Duration(milliseconds: 500),
                      ),

                  const SizedBox(height: 8),

                  Text(
                    'AI insights, thought patterns\n& dump rate analytics',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 350),
                        duration: const Duration(milliseconds: 500),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
