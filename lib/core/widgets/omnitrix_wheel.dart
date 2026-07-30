import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindwipe/core/theme/app_colors.dart';

/// The bottom navigation wheel with pull-up-to-add gesture.
///
/// Layout:
///   ⚡ Habits  ─── ( + ) ───  🧠 Mind
///         ╰─────────────────╯
///
/// The center "+" can be held and dragged upward — it inflates
/// into a text input field for adding tasks.
///
/// 🧠 LEARN: This widget combines several advanced concepts:
/// - [CustomPainter] for the arc shape
/// - [GestureDetector] for drag handling
/// - [AnimationController] for smooth morphing
/// - [Transform] and interpolation for the inflate effect
class BottomWheel extends StatefulWidget {
  const BottomWheel({
    super.key,
    required this.onTaskAdded,
    required this.onHabitsTap,
    required this.onMindTap,
    this.currentIndex = 0,
  });

  final ValueChanged<String> onTaskAdded;
  final VoidCallback onHabitsTap;
  final VoidCallback onMindTap;
  final int currentIndex;

  @override
  State<BottomWheel> createState() => _BottomWheelState();
}

class _BottomWheelState extends State<BottomWheel>
    with TickerProviderStateMixin {
  // ─── Pull-up animation state ─────────────────────────────
  late AnimationController _morphController;
  late AnimationController _snapBackController;
  late Animation<double> _snapBackAnimation;

  double _dragOffset = 0.0;       // How far up the user has dragged
  bool _isDragging = false;
  bool _isInputOpen = false;
  final double _dragThreshold = 120.0; // Distance to fully open

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOutBack,
    );
    _snapBackController.addListener(() {
      setState(() {
        _dragOffset = lerpDouble(
          _dragOffset,
          0.0,
          _snapBackAnimation.value,
        )!;
      });
    });
  }

  @override
  void dispose() {
    _morphController.dispose();
    _snapBackController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Progress from 0.0 (circle) to 1.0 (fully open input)
  double get _morphProgress => (_dragOffset / _dragThreshold).clamp(0.0, 1.0);

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isInputOpen) return;
    _isDragging = true;
    _snapBackController.reset();
    HapticFeedback.lightImpact();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isInputOpen) return;
    setState(() {
      // Negative delta.dy means dragging up
      _dragOffset = (_dragOffset - details.delta.dy).clamp(0.0, _dragThreshold + 30);
    });

    // Haptic ticks at key thresholds
    if (_morphProgress > 0.5 && _morphProgress < 0.52) {
      HapticFeedback.selectionClick();
    }
    if (_morphProgress >= 0.98 && !_isInputOpen) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    if (_morphProgress >= 0.7) {
      // Open the input
      setState(() {
        _isInputOpen = true;
        _dragOffset = _dragThreshold;
      });
      _morphController.forward();
      // Auto-focus the text field
      Future.delayed(const Duration(milliseconds: 200), () {
        _focusNode.requestFocus();
      });
    } else {
      // Snap back to circle
      _snapBackController.forward(from: 0.0);
    }
  }

  void _submitTask() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onTaskAdded(text);
      HapticFeedback.mediumImpact();
    }
    _closeInput();
  }

  void _closeInput() {
    _focusNode.unfocus();
    _textController.clear();
    setState(() {
      _isInputOpen = false;
    });
    _morphController.reverse();
    // Animate back down
    _snapBackController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final wheelRadius = screenWidth * 0.42;
    final wheelHeight = wheelRadius * 0.38;

    return SizedBox(
      width: screenWidth,
      height: wheelHeight + _dragOffset + 60, // Extra space for the inflating button
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ─── Wheel Arc Background ────────────────────────────
          Positioned(
            bottom: 0,
            child: CustomPaint(
              size: Size(screenWidth, wheelHeight),
              painter: _WheelArcPainter(radius: wheelRadius),
            ),
          ),

          // ─── Left: Habits ────────────────────────────────────
          Positioned(
            bottom: 12,
            left: screenWidth * 0.15,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onHabitsTap();
              },
              child: _buildNavItem(
                icon: Icons.bolt_rounded,
                label: 'Habits',
                isSelected: widget.currentIndex == 1,
              ),
            ),
          ),

          // ─── Right: Mind ─────────────────────────────────────
          Positioned(
            bottom: 12,
            right: screenWidth * 0.15,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onMindTap();
              },
              child: _buildNavItem(
                icon: Icons.psychology_rounded,
                label: 'Mind',
                isSelected: widget.currentIndex == 2,
              ),
            ),
          ),

          // ─── Center: Add Button (morphable) ──────────────────
          Positioned(
            bottom: wheelHeight * 0.35,
            child: GestureDetector(
              onVerticalDragStart: _onVerticalDragStart,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              onTap: () {
                if (!_isInputOpen) {
                  // Quick tap — open immediately
                  setState(() {
                    _isInputOpen = true;
                    _dragOffset = _dragThreshold;
                  });
                  _morphController.forward();
                  Future.delayed(const Duration(milliseconds: 200), () {
                    _focusNode.requestFocus();
                  });
                  HapticFeedback.mediumImpact();
                }
              },
              child: Transform.translate(
                offset: Offset(0, -_dragOffset),
                child: AnimatedContainer(
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: _isInputOpen
                      ? screenWidth - 48
                      : lerpDouble(48, screenWidth - 48, _morphProgress)!,
                  height: _isInputOpen
                      ? 52
                      : lerpDouble(48, 52, _morphProgress)!,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      AppColors.backgroundSurface,
                      AppColors.backgroundElevated,
                      _morphProgress,
                    ),
                    borderRadius: BorderRadius.circular(
                      lerpDouble(24, 26, _morphProgress)!,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: lerpDouble(0.10, 0.08, _morphProgress)!,
                      ),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: lerpDouble(0.2, 0.4, _morphProgress)!,
                        ),
                        blurRadius: lerpDouble(8, 24, _morphProgress)!,
                        offset: Offset(0, lerpDouble(2, 8, _morphProgress)!),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: _morphProgress < 0.5 && !_isInputOpen
                      ? Icon(
                          Icons.add_rounded,
                          size: lerpDouble(24, 20, _morphProgress),
                          color: AppColors.textPrimary.withValues(
                            alpha: lerpDouble(1.0, 0.0, _morphProgress * 2)!,
                          ),
                        )
                      : _buildInputField(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? AppColors.textPrimary
                : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
            color: isSelected
                ? AppColors.textSecondary
                : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Dump a thought...',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onSubmitted: (_) => _submitTask(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _submitTask,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the subtle half-circle arc for the wheel background.
class _WheelArcPainter extends CustomPainter {
  _WheelArcPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);

    // Main fill
    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.2,
        colors: [
          const Color(0xFF1A1A1A),
          const Color(0xFF111111),
          const Color(0xFF0A0A0A),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      pi, pi, true, fillPaint,
    );

    // Border arc
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.06);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      pi, pi, false, borderPaint,
    );

    // Tiny notch marks
    final notchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.8;

    for (int i = 1; i < 10; i++) {
      final angle = pi + (i * pi / 10);
      final innerR = radius * 0.79;
      final outerR = radius * 0.83;
      canvas.drawLine(
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        notchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WheelArcPainter oldDelegate) => false;
}
