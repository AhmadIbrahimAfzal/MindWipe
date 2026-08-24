import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mindwipe/core/theme/app_colors.dart';
import 'package:mindwipe/features/habits/domain/entities/habit.dart';
import 'package:mindwipe/features/habits/presentation/providers/habits_provider.dart';
import 'package:mindwipe/features/habits/presentation/widgets/habit_icon_helper.dart';
import 'package:mindwipe/features/habits/presentation/widgets/habit_matrix_grid.dart';

/// Modal sheet for Creating or Editing a Habit.
///
/// Features:
/// - Icon preview with glowing backdrop.
/// - Icon picker grid.
/// - Name & Description inputs.
/// - 16-color curated palette.
/// - Habit type toggle ('build' vs 'quit').
/// - Interactive History / Missed Day editor matrix.
/// - Delete button (for existing habits).
/// - Floating Save button.
class EditHabitSheet extends ConsumerStatefulWidget {
  const EditHabitSheet({
    super.key,
    this.habit,
  });

  final Habit? habit;

  @override
  ConsumerState<EditHabitSheet> createState() => _EditHabitSheetState();
}

class _EditHabitSheetState extends ConsumerState<EditHabitSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedIconKey;
  late int _selectedColorValue;
  late String _habitType;
  late Set<String> _completedDates;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descriptionController = TextEditingController(text: h?.description ?? '');
    _selectedIconKey = h?.iconKey ?? 'sport';
    _selectedColorValue = h?.colorValue ?? HabitIconHelper.paletteColors[8]; // Indigo default
    _habitType = h?.habitType ?? 'build';
    _completedDates = Set<String>.from(h?.completedDates ?? {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    HapticFeedback.mediumImpact();

    if (_isEditing) {
      final updated = widget.habit!.copyWith(
        name: name,
        description: _descriptionController.text.trim(),
        iconKey: _selectedIconKey,
        colorValue: _selectedColorValue,
        habitType: _habitType,
        completedDates: _completedDates,
      );
      ref.read(habitsProvider.notifier).updateHabit(updated);
    } else {
      ref.read(habitsProvider.notifier).createHabit(
            name: name,
            description: _descriptionController.text.trim(),
            iconKey: _selectedIconKey,
            colorValue: _selectedColorValue,
            habitType: _habitType,
          );
    }

    Navigator.of(context).pop();
  }

  void _onDelete() {
    if (!_isEditing) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Habit',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.habit!.name}"? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              Navigator.of(context).pop(); // Close sheet
              ref.read(habitsProvider.notifier).deleteHabit(widget.habit!.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = Color(_selectedColorValue);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF101012),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ─── Header ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  Text(
                    _isEditing ? 'Edit Habit' : 'New Habit',
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      onPressed: _onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 22,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // ─── Scrollable Form ────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset + 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Icon Preview (Clean Matte)
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentColor.withValues(alpha: 0.18),
                        border: Border.all(
                          color: currentColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        HabitIconHelper.getIcon(_selectedIconKey),
                        color: currentColor,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Icon Selector Strip
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: HabitIconHelper.availableIcons.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = HabitIconHelper.availableIcons[index];
                        final isSelected = item['key'] == _selectedIconKey;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedIconKey = item['key'] as String;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? currentColor.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? currentColor
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 0.8,
                              ),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? currentColor
                                  : AppColors.textTertiary,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // NAME Field
                  _buildSectionHeader('NAME'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: TextField(
                      controller: _nameController,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Sport, Guitar, Reading',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // DESCRIPTION Field
                  _buildSectionHeader('DESCRIPTION'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: TextField(
                      controller: _descriptionController,
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Weightlifting, running or similar',
                        hintStyle: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // COLOR Palette
                  _buildSectionHeader('COLOR'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: HabitIconHelper.paletteColors.map((colorValue) {
                      final isSelected = colorValue == _selectedColorValue;
                      final col = Color(colorValue);
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedColorValue = colorValue;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: col,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.5)
                                : null,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // HABIT TYPE Toggle
                  _buildSectionHeader('HABIT TYPE'),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _habitType = 'build');
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _habitType == 'build'
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Build a habit',
                                  style: TextStyle(
                                    color: _habitType == 'build'
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                    fontWeight: _habitType == 'build'
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _habitType = 'quit');
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _habitType == 'quit'
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Quit a habit',
                                  style: TextStyle(
                                    color: _habitType == 'quit'
                                        ? AppColors.textPrimary
                                        : AppColors.textTertiary,
                                    fontWeight: _habitType == 'quit'
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Interactive History / Missed Day Editor (if editing existing habit)
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('EDIT MISSED DAYS (TAP TO TOGGLE)'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HabitMatrixGrid(
                            completedDates: _completedDates,
                            color: currentColor,
                            numWeeks: 18,
                            rows: 6,
                            interactive: true,
                            onDateTap: (dateStr) {
                              setState(() {
                                if (_completedDates.contains(dateStr)) {
                                  _completedDates.remove(dateStr);
                                } else {
                                  _completedDates.add(dateStr);
                                }
                              });
                              // Also toggle in persistent DB
                              ref
                                  .read(habitsProvider.notifier)
                                  .toggleDate(widget.habit!.id, dateStr);
                            },
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'Tap any past box above to mark or unmark missed days',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Floating Clean SAVE Button
                  GestureDetector(
                    onTap: _onSave,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: currentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Save',
                          style: GoogleFonts.outfit(
                            color: currentColor.computeLuminance() > 0.6
                                ? Colors.black
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
