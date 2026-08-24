import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/core/services/audio_service.dart';

/// Clean, bubbly bottom navigation bar with a morphable "+" thought capture button.
///
/// 🧠 LEARN:
/// - Three-tab layout: [Habits] on the left, [Inbox] in the center, [MindMap] on the right.
/// - Active page title appears bold and bubbly in bright white, while side titles are in faded grey.
/// - The circular [+] button sits directly above the center label and expands into the
///   "Dump a thought..." text input bar on tap or drag.
/// - The upwards submit arrow is 100% responsive with direct touch handling.
/// - 1-Swipe Back Dismissal: Automatically collapses on the first Android back swipe.
class FluidBottomNav extends StatefulWidget {
  const FluidBottomNav({
    super.key,
    required this.pageController,
    required this.onTaskAdded,
  });

  final PageController pageController;
  final ValueChanged<String> onTaskAdded;

  @override
  State<FluidBottomNav> createState() => _FluidBottomNavState();
}

class _FluidBottomNavState extends State<FluidBottomNav>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ─── Page State ──────────────────────────────────────────
  double _currentPage = 1.0;
  int _lastTickPage = 1;

  // ─── Add Button Morph State ──────────────────────────────
  late AnimationController _morphController;
  late AnimationController _snapBackController;
  late Animation<double> _snapBackAnimation;

  double _dragOffset = 0.0;
  bool _isDraggingAddButton = false;
  bool _isInputOpen = false;
  bool _wasKeyboardOpen = false;
  final double _dragThreshold = 80.0;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _pageLabels = ['Habits', 'Inbox', 'MindMap'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    widget.pageController.addListener(_onPageScroll);

    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
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

  void _onPageScroll() {
    if (!widget.pageController.hasClients) return;
    final page = widget.pageController.page ?? 1.0;
    final rounded = page.round();
    if (rounded != _lastTickPage) {
      _lastTickPage = rounded;
      AudioFeedback.playTick();
    }
    setState(() {
      _currentPage = page;
    });
  }

  void _goToPage(int index) {
    AudioFeedback.playTick();
    widget.pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  double get _morphProgress => (_dragOffset / _dragThreshold).clamp(0.0, 1.0);

  void _onVerticalDragStart(DragStartDetails details) {
    if (_isInputOpen) return;
    _isDraggingAddButton = true;
    _snapBackController.reset();
    AudioFeedback.playPop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDraggingAddButton || _isInputOpen) return;
    setState(() {
      _dragOffset = (_dragOffset - details.delta.dy).clamp(0.0, _dragThreshold + 20);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDraggingAddButton) return;
    _isDraggingAddButton = false;

    if (_morphProgress >= 0.5) {
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
    Future.delayed(const Duration(milliseconds: 100), () {
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

    return PopScope(
      canPop: !_isInputOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isInputOpen) {
          _closeInput();
        }
      },
      child: Container(
        width: screenWidth,
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Morphable + / "Dump a Thought" Bar ─────────────
            GestureDetector(
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
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: _isInputOpen
                    ? screenWidth - 44
                    : lerpDouble(50, screenWidth - 44, _morphProgress)!,
                height: _isInputOpen ? 52 : lerpDouble(50, 52, _morphProgress)!,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFF1E1E22),
                    const Color(0xFF141416),
                    _morphProgress,
                  ),
                  borderRadius: BorderRadius.circular(
                    lerpDouble(25, 26, _morphProgress)!,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: lerpDouble(0.12, 0.08, _morphProgress)!,
                    ),
                    width: 0.75,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: lerpDouble(0.3, 0.6, _morphProgress)!,
                      ),
                      blurRadius: lerpDouble(10, 20, _morphProgress)!,
                      offset: Offset(0, lerpDouble(3, 6, _morphProgress)!),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: _morphProgress < 0.4 && !_isInputOpen
                    ? const Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : _buildInputField(),
              ),
            ),

            const SizedBox(height: 14),

            // ─── 3-Tab Bottom Title Row ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Habits (faded when on Inbox/MindMap)
                  _buildNavTitle(
                    index: 0,
                    label: _pageLabels[0],
                    alignment: Alignment.centerLeft,
                  ),

                  // Center: Inbox (bold & prominent when active)
                  _buildNavTitle(
                    index: 1,
                    label: _pageLabels[1],
                    alignment: Alignment.center,
                  ),

                  // Right: MindMap (faded when on Habits/Inbox)
                  _buildNavTitle(
                    index: 2,
                    label: _pageLabels[2],
                    alignment: Alignment.centerRight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTitle({
    required int index,
    required String label,
    required Alignment alignment,
  }) {
    // Distance from current scroll position
    final double distance = (_currentPage - index).abs().clamp(0.0, 1.0);
    final double activeWeight = 1.0 - distance; // 1.0 when active, 0.0 when distant

    // Interpolate font size, color and opacity
    final double fontSize = lerpDouble(13.0, 18.0, activeWeight)!;
    final Color textColor = Color.lerp(
      const Color(0xFF636366), // Muted greyish tone
      const Color(0xFFF2F2F7), // Bold bubbly bright white
      activeWeight,
    )!;
    final FontWeight fontWeight = activeWeight > 0.6 ? FontWeight.w700 : FontWeight.w500;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _goToPage(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        alignment: alignment,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
            letterSpacing: activeWeight > 0.6 ? -0.3 : 0.2,
          ),
          child: Text(label),
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
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Dump a thought...',
                hintStyle: GoogleFonts.inter(
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

          // ─── Direct Upwards Arrow Submit Button ─────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _submitTask,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
