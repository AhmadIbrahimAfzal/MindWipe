import 'package:flutter/material.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/widgets/glass_card.dart';

/// The translucent input bar at the bottom of the Inbox screen.
///
/// 🧠 LEARN: This is designed to feel like it's "floating" over the content.
/// In Phase 2, we'll wire up the [TextField] to actually add tasks.
/// For now, it's just visual.
///
/// Notice we use [GlassCard] again — reusable widgets save you from
/// duplicating blur/border code everywhere.
class QuickAddBar extends StatelessWidget {
  const QuickAddBar({
    super.key,
    this.onSubmitted,
  });

  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      blurAmount: 32,
      opacity: 0.12,
      borderRadius: 24,
      child: Row(
        children: [
          // ─── Text Input ────────────────────────────────────
          Expanded(
            child: TextField(
              onSubmitted: onSubmitted,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Dump a thought...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
                // Override theme's input decoration for this specific use
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // ─── Send Button ───────────────────────────────────
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.accentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Phase 2 — wire up to state management
              },
              icon: Icon(
                Icons.arrow_upward_rounded,
                color: AppColors.backgroundDeep,
                size: 22,
              ),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
