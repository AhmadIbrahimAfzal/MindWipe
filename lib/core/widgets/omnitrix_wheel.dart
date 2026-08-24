import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/services/audio_service.dart';

/// An Omnitrix-style Rotary Dial Navigation with a center pull-up Add Button.
///
/// 🧠 LEARN:
/// - Outer Ring: Stays a solid, consistent luxury color at the bottom of the screen.
/// - Hit-Test Safe: Container dynamically sizes its render box so the inflated input
///   pill and upwards submit arrow are 100% within the touchable bounds.
/// - One-Swipe Back Dismissal: Uses [WidgetsBindingObserver] to instantly collapse
///   the input pill on the very first Android back gesture (when keyboard lowers).
/// - Tactile Sound & Haptics: Integrated with [AudioFeedback] for ratchet ticks and pops.
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ─── Dial Rotation State ─────────────────────────────────
  double _rotationAngle = 0.0;
  double _startDragAngle = 0.0;
  double _startRotationAngle = 0.0;
  bool _isRotatingDial = false;
  int _lastTickPageIndex = 1;

  // ─── Center Add Button Morph State ───────────────────────
  late AnimationController _morphController;
  late AnimationController _snapBackController;
  late Animation<double> _snapBackAnimation;

  double _dragOffset = 0.0;
  bool _isDraggingAddButton = false;
  bool _isInputOpen = false;
  bool _wasKeyboardOpen = false;
  final double _dragThreshold = 110.0;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Spacing between our 3 navigation items in radians (120 degrees)
  static const double _angleInterval = 2 * pi / 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen to PageController to update the dial rotation when page changes
    widget.pageController.addListener(_onPageScroll);

    // Initialize animation controllers for the center button morphing
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOutCubic,
    );
    _snapBackController.addListener(() {
      setState(() {
        _dragOffset = lerpDouble(_dragOffset, 0.0, _snapBackAnimation.value)!;
      });
    });

    // Safety net: close input when focus is lost
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isInputOpen) {
        _closeInput();
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom;
    final isKeyboardCurrentlyOpen = bottomInset > 0;

    if (_isInputOpen && _wasKeyboardOpen && !isKeyboardCurrentlyOpen) {
      _closeInput();
    }
    _wasKeyboardOpen = isKeyboardCurrentlyOpen;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    final roundedPage = page.round();

    if (roundedPage != _lastTickPageIndex) {
      _lastTickPageIndex = roundedPage;
      AudioFeedback.playTick();
    }

    setState(() {
      _rotationAngle = (1.0 - page) * _angleInterval;
    });
  }

  // ─── Rotary Dial Math & Interaction ──────────────────────
  void _onDialPanStart(DragStartDetails details, Offset center) {
    if (_isInputOpen || _isDraggingAddButton) return;
    _isRotatingDial = true;

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
      _rotationAngle = (_startRotationAngle + angleDiff).clamp(-_angleInterval, _angleInterval);

      if (widget.pageController.hasClients) {
        final targetPage = 1.0 - (_rotationAngle / _angleInterval);
        widget.pageController.jumpTo(targetPage * widget.pageController.position.maxScrollExtent / 2);
      }
    });
  }

  void _onDialPanEnd(DragEndDetails details) {
    if (!_isRotatingDial) return;
    _isRotatingDial = false;

    final targetPage = (1.0 - (_rotationAngle / _angleInterval)).round().clamp(0, 2);

    if (widget.pageController.hasClients) {
      widget.pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    setState(() {
      _rotationAngle = (1.0 - targetPage) * _angleInterval;
    });

    AudioFeedback.playTick();
  }

  // ─── Morphable Add Button Math ───────────────────────────
  double get _morphProgress => (_dragOffset / _dragThreshold).clamp(0.0, 1.0);

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isInputOpen || _isRotatingDial) return;
    _isDraggingAddButton = true;
    _snapBackController.reset();
    AudioFeedback.playPop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDraggingAddButton || _isInputOpen) return;
    setState(() {
      _dragOffset = (_dragOffset - details.delta.dy).clamp(0.0, _dragThreshold + 25);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDraggingAddButton) return;
    _isDraggingAddButton = false;

    if (_morphProgress >= 0.55) {
      _openInput();
    } else {
      _snapBackController.forward(from: 0.0);
    }
  }

  void _openInput() {
    setState(() {
      _isInputOpen = true;
      _dragOffset = _dragThreshold;
    });
    _morphController.forward();
    AudioFeedback.playPop();
    Future.delayed(const Duration(milliseconds: 150), () {
      _focusNode.requestFocus();
    });
  }

  void _submitTask() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onTaskAdded(text);
      AudioFeedback.playPop();
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
    final dialCenter = Offset(screenWidth / 2, dialHeight + 20);

    // Total height of the widget box encompasses the inflated input bar
    // so touches are NEVER clipped by the render box bounds!
    final totalWidgetHeight = dialHeight + _dragOffset + 40;

    return PopScope(
      canPop: !_isInputOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isInputOpen) {
          _closeInput();
        }
      },
      child: SizedBox(
        width: screenWidth,
        height: totalWidgetHeight,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // ─── 1. Solid Stationary Base Dial & Rotating Icons ─
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: dialHeight + 20,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Base Dial Arc
                  Positioned(
                    bottom: 0,
                    child: GestureDetector(
                      onPanStart: (d) => _onDialPanStart(d, dialCenter),
                      onPanUpdate: (d) => _onDialPanUpdate(d, dialCenter),
                      onPanEnd: _onDialPanEnd,
                      child: CustomPaint(
                        size: Size(screenWidth, dialHeight),
                        painter: _SolidDialPainter(
                          radius: dialRadius,
                          center: dialCenter,
                        ),
                        child: Transform.rotate(
                          angle: _rotationAngle,
                          alignment: Alignment.bottomCenter,
                          child: CustomPaint(
                            size: Size(screenWidth, dialHeight),
                            painter: _DialNotchesPainter(
                              radius: dialRadius,
                              center: dialCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Habits Indicator (+120 deg)
                  _buildRotatingIcon(
                    angle: 5 * pi / 6,
                    center: dialCenter,
                    radius: dialRadius * 0.65,
                    icon: Icons.bolt_rounded,
                    label: 'Habits',
                  ),

                  // Inbox Indicator (Top Center -90 deg)
                  _buildRotatingIcon(
                    angle: -pi / 2,
                    center: dialCenter,
                    radius: dialRadius * 0.65,
                    icon: Icons.layers_rounded,
                    label: 'Inbox',
                  ),

                  // Mind Indicator (-120 deg)
                  _buildRotatingIcon(
                    angle: pi / 6,
                    center: dialCenter,
                    radius: dialRadius * 0.65,
                    icon: Icons.psychology_rounded,
                    label: 'Mind',
                  ),
                ],
              ),
            ),

            // ─── 2. Center Add Button / Input Bar ───────────────
            // Positioned dynamically via bottom offset — 100% within touchable bounds!
            Positioned(
              bottom: dialHeight * 0.28 + _dragOffset,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _isInputOpen ? null : _onVerticalDragStart,
                onVerticalDragUpdate: _isInputOpen ? null : _onVerticalDragUpdate,
                onVerticalDragEnd: _isInputOpen ? null : _onVerticalDragEnd,
                onTap: () {
                  if (!_isInputOpen) {
                    _openInput();
                  }
                },
                child: AnimatedContainer(
                  duration: _isDraggingAddButton
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  width: _isInputOpen
                      ? screenWidth - 48
                      : lerpDouble(44, screenWidth - 48, _morphProgress)!,
                  height: _isInputOpen
                      ? 50
                      : lerpDouble(44, 50, _morphProgress)!,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFF1E1E22),
                      const Color(0xFF161618),
                      _morphProgress,
                    ),
                    borderRadius: BorderRadius.circular(
                      lerpDouble(22, 25, _morphProgress)!,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: lerpDouble(0.12, 0.08, _morphProgress)!,
                      ),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: lerpDouble(0.3, 0.5, _morphProgress)!,
                        ),
                        blurRadius: lerpDouble(10, 24, _morphProgress)!,
                        offset: Offset(0, lerpDouble(3, 8, _morphProgress)!),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: _morphProgress < 0.5 && !_isInputOpen
                      ? const Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : _buildInputField(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRotatingIcon({
    required double angle,
    required Offset center,
    required double radius,
    required IconData icon,
    required String label,
  }) {
    final targetAngle = angle + _rotationAngle;
    final double x = center.dx + radius * cos(targetAngle);
    final double y = center.dy + radius * sin(targetAngle);

    final angleDiffFromTop = (sin(targetAngle) + 1.0).clamp(0.0, 2.0);
    final double opacity = lerpDouble(1.0, 0.50, (angleDiffFromTop / 1.2).clamp(0.0, 1.0))!;
    final bool isSelected = (sin(targetAngle) < -0.85);

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
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.5,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
              decoration: const InputDecoration(
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
          const SizedBox(width: 4),

          // ─── Direct Upwards Arrow Submit Button ─────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _submitTask,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  size: 17,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Solid, consistent dial background that never fades or shifts color across pages.
class _SolidDialPainter extends CustomPainter {
  _SolidDialPainter({
    required this.radius,
    required this.center,
  });

  final double radius;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF141416)
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      pi,
      pi,
      true,
      fillPaint,
    );

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = Colors.white.withValues(alpha: 0.08);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      pi,
      pi,
      false,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SolidDialPainter oldDelegate) => false;
}

/// Rotating ratchet notches along the outer perimeter.
class _DialNotchesPainter extends CustomPainter {
  _DialNotchesPainter({
    required this.radius,
    required this.center,
  });

  final double radius;
  final Offset center;

  @override
  void paint(Canvas canvas, Size size) {
    final notchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 18; i++) {
      final angle = pi + (i * pi / 18);
      final innerR = radius * 0.78;
      final outerR = radius * 0.83;
      canvas.drawLine(
        Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle)),
        Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle)),
        notchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialNotchesPainter oldDelegate) => false;
}
