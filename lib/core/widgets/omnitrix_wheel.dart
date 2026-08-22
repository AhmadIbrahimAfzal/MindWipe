import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindwipe/core/theme/app_colors.dart';

/// An Omnitrix-style Rotary Dial Navigation with a center pull-up Add Button.
///
/// 🧠 LEARN:
/// - Outer Ring: Rotates based on circular gesture tracking via [atan2].
/// - Sync: Tied to a [PageController] and a [PageView]. Swiping pages rotates the dial,
///   and rotating the dial swipes the pages.
/// - Center Button: Static (does not rotate). Can be dragged vertically to inflate
///   a text entry box for adding tasks.
class RotaryOmnitrixWheel extends StatefulWidget {
  const RotaryOmnitrixWheel({
    super.key,
    required this.pageController,
    required this.onTaskAdded,
  });

  final PageController pageController;
  final ValueChanged<String> onTaskAdded;

  @override
  State<RotaryOmnitrixWheel> createState() => _RotaryOmnitrixWheelState();
}

class _RotaryOmnitrixWheelState extends State<RotaryOmnitrixWheel>
    with TickerProviderStateMixin {
  // ─── Dial Rotation State ─────────────────────────────────
  double _rotationAngle = 0.0;
  double _startDragAngle = 0.0;
  double _startRotationAngle = 0.0;
  bool _isRotatingDial = false;

  // ─── Center Add Button Morph State ───────────────────────
  late AnimationController _morphController;
  late AnimationController _snapBackController;
  late Animation<double> _snapBackAnimation;

  double _dragOffset = 0.0;
  bool _isDraggingAddButton = false;
  bool _isInputOpen = false;
  final double _dragThreshold = 120.0;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Spacing between our 3 navigation items in radians (120 degrees)
  static const double _angleInterval = 2 * pi / 3;

  @override
  void initState() {
    super.initState();

    // Listen to PageController to update the dial rotation when page changes
    widget.pageController.addListener(_onPageScroll);

    // Initialize animation controllers for the center button morphing
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
        _dragOffset = lerpDouble(_dragOffset, 0.0, _snapBackAnimation.value)!;
      });
    });
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageScroll);
    _morphController.dispose();
    _snapBackController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Sync scroll from PageController to dial rotation
  void _onPageScroll() {
    if (_isRotatingDial || !widget.pageController.hasClients) return;
    final page = widget.pageController.page ?? 0.0;
    setState(() {
      // Map Page 0 -> +120 deg, Page 1 -> 0 deg, Page 2 -> -120 deg
      _rotationAngle = (1.0 - page) * _angleInterval;
    });
  }

  // ─── Rotary Dial Math & Interaction ──────────────────────
  void _onDialPanStart(DragStartDetails details, Offset center) {
    if (_isInputOpen || _isDraggingAddButton) return;
    _isRotatingDial = true;

    // Find starting touch angle relative to the dial center point
    final touchPos = details.localPosition;
    _startDragAngle = atan2(touchPos.dy - center.dy, touchPos.dx - center.dx);
    _startRotationAngle = _rotationAngle;
  }

  void _onDialPanUpdate(DragUpdateDetails details, Offset center) {
    if (!_isRotatingDial) return;

    final touchPos = details.localPosition;
    final currentDragAngle = atan2(touchPos.dy - center.dy, touchPos.dx - center.dx);
    final angleDiff = currentDragAngle - _startDragAngle;

    setState(() {
      // Update dial rotation within bounds
      // Habits (page 0) = +120 deg (2*pi/3), Mind (page 2) = -120 deg (-2*pi/3)
      _rotationAngle = (_startRotationAngle + angleDiff).clamp(-_angleInterval, _angleInterval);

      // Sync rotation back to the PageView scroll position
      if (widget.pageController.hasClients) {
        final targetPage = 1.0 - (_rotationAngle / _angleInterval);
        widget.pageController.jumpTo(targetPage * widget.pageController.position.maxScrollExtent / 2);
      }
    });
  }

  void _onDialPanEnd(DragEndDetails details) {
    if (!_isRotatingDial) return;
    _isRotatingDial = false;

    // Snapping logic: Find closest page target (0, 1, or 2)
    final targetPage = (1.0 - (_rotationAngle / _angleInterval)).round().clamp(0, 2);

    // Animate both PageView and Dial to clean alignments
    if (widget.pageController.hasClients) {
      widget.pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    setState(() {
      _rotationAngle = (1.0 - targetPage) * _angleInterval;
    });

    HapticFeedback.mediumImpact();
  }

  // ─── Morphable Add Button Math ───────────────────────────
  double get _morphProgress => (_dragOffset / _dragThreshold).clamp(0.0, 1.0);

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isInputOpen || _isRotatingDial) return;
    _isDraggingAddButton = true;
    _snapBackController.reset();
    HapticFeedback.lightImpact();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDraggingAddButton || _isInputOpen) return;
    setState(() {
      _dragOffset = (_dragOffset - details.delta.dy).clamp(0.0, _dragThreshold + 30);
    });

    if (_morphProgress > 0.5 && _morphProgress < 0.52) {
      HapticFeedback.selectionClick();
    }
    if (_morphProgress >= 0.98 && !_isInputOpen) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDraggingAddButton) return;
    _isDraggingAddButton = false;

    if (_morphProgress >= 0.7) {
      setState(() {
        _isInputOpen = true;
        _dragOffset = _dragThreshold;
      });
      _morphController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _focusNode.requestFocus();
      });
    } else {
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
    _snapBackController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialRadius = screenWidth * 0.44;
    final dialHeight = dialRadius * 0.45;
    final dialCenter = Offset(screenWidth / 2, dialHeight + 20); // Center point of the circular canvas

    return SizedBox(
      width: screenWidth,
      height: dialHeight + _dragOffset + 60,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ─── Outer Rotating Dial ─────────────────────────────
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onPanStart: (d) => _onDialPanStart(d, dialCenter),
              onPanUpdate: (d) => _onDialPanUpdate(d, dialCenter),
              onPanEnd: _onDialPanEnd,
              child: Transform.rotate(
                angle: _rotationAngle,
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                  size: Size(screenWidth, dialHeight),
                  painter: _RotaryDialPainter(
                    radius: dialRadius,
                    center: dialCenter,
                  ),
                ),
              ),
            ),
          ),

          // ─── Habits Indicator ───
          // Place icon at +120 deg (angle = 5*pi/6) on the wheel circle
          _buildRotatingIcon(
            angle: 5 * pi / 6,
            center: dialCenter,
            radius: dialRadius * 0.65,
            icon: Icons.bolt_rounded,
            label: 'Habits',
          ),

          // ─── Inbox Indicator ───
          // Place icon at top center (angle = -pi/2) on the wheel circle
          _buildRotatingIcon(
            angle: -pi / 2,
            center: dialCenter,
            radius: dialRadius * 0.65,
            icon: Icons.layers_rounded,
            label: 'Inbox',
          ),

          // ─── Mind Indicator ───
          // Place icon at -120 deg (angle = pi/6) on the wheel circle
          _buildRotatingIcon(
            angle: pi / 6,
            center: dialCenter,
            radius: dialRadius * 0.65,
            icon: Icons.psychology_rounded,
            label: 'Mind',
          ),

          // ─── Static Center Add Button (Morphable Input) ───────
          Positioned(
            bottom: dialHeight * 0.28,
            child: GestureDetector(
              onVerticalDragStart: _onVerticalDragStart,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              onTap: () {
                if (!_isInputOpen) {
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
                  duration: _isDraggingAddButton ? Duration.zero : const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: _isInputOpen ? screenWidth - 48 : lerpDouble(44, screenWidth - 48, _morphProgress)!,
                  height: _isInputOpen ? 50 : lerpDouble(44, 50, _morphProgress)!,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      AppColors.backgroundSurface,
                      AppColors.backgroundElevated,
                      _morphProgress,
                    ),
                    borderRadius: BorderRadius.circular(
                      lerpDouble(22, 25, _morphProgress)!,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: lerpDouble(0.12, 0.06, _morphProgress)!,
                      ),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: lerpDouble(0.2, 0.4, _morphProgress)!,
                        ),
                        blurRadius: lerpDouble(8, 20, _morphProgress)!,
                        offset: Offset(0, lerpDouble(2, 6, _morphProgress)!),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: _morphProgress < 0.5 && !_isInputOpen
                      ? Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
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

  // Builds navigation icons that rotate with the wheel arc
  Widget _buildRotatingIcon({
    required double angle,
    required Offset center,
    required double radius,
    required IconData icon,
    required String label,
  }) {
    // Calculate layout position on the dial circle
    final targetAngle = angle + _rotationAngle;
    final double x = center.dx + radius * cos(targetAngle);
    final double y = center.dy + radius * sin(targetAngle);

    // Fade icon out if it goes below the horizontal dial baseline
    final double opacity = max(0.0, sin(targetAngle) * -1.0).clamp(0.0, 1.0);

    return Positioned(
      left: x - 25,
      top: y - 25,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: 50,
            height: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw the dial arc container.
class _RotaryDialPainter extends CustomPainter {
  _RotaryDialPainter({
    required this.radius,
    required this.center,
  });

  final double radius;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    // Draws the solid dial half-circle
    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.1,
        colors: [
          const Color(0xFF1C1C1E),
          const Color(0xFF121213),
          const Color(0xFF070707),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      pi, pi, true, fillPaint,
    );

    // Subtle edge border lines
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.05);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      pi, pi, false, borderPaint,
    );

    // Draw notch highlights along the dial
    final notchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 0.8;

    for (int i = 1; i < 15; i++) {
      final angle = pi + (i * pi / 15);
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
  bool shouldRepaint(covariant _RotaryDialPainter oldDelegate) => false;
}
