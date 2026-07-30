import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindwipe/core/theme/app_colors.dart';

/// The floating circular "+" add task button.
///
/// 🧠 LEARN: This sits between the task list and the Omnitrix wheel.
/// It has a subtle pulsing glow animation to draw attention.
/// [AnimationController] drives the glow — it loops forever between
/// 0.0 and 1.0, and we use that to animate the shadow's opacity.
class AddTaskButton extends StatefulWidget {
  const AddTaskButton({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  State<AddTaskButton> createState() => _AddTaskButtonState();
}

class _AddTaskButtonState extends State<AddTaskButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowOpacity = 0.1 + (_glowController.value * 0.15);
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: glowOpacity),
                blurRadius: 20 + (_glowController.value * 10),
                spreadRadius: -2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onPressed?.call();
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundSurface,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
