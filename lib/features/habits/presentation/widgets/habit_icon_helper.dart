import 'package:flutter/material.dart';

/// Helper mapping for habit icons and curated aesthetic color palette.
class HabitIconHelper {
  HabitIconHelper._();

  /// Curated 16 vibrant colors from the HabitKit reference design.
  static const List<int> paletteColors = [
    0xFFFF5252, // Coral Red
    0xFFFF7A00, // Tangerine Orange
    0xFFFFB800, // Amber Yellow
    0xFFFFE600, // Sun Yellow
    0xFF76E243, // Lime Green
    0xFF00E676, // Mint Green
    0xFF00E5FF, // Cyan
    0xFF2979FF, // Bright Blue
    0xFF6366F1, // Indigo / Violet
    0xFF8B5CF6, // Purple
    0xFFD946EF, // Fuchsia / Magenta
    0xFFFF4081, // Hot Pink
    0xFFFF6E6E, // Soft Rose
    0xFF64748B, // Slate Blue
    0xFF94A3B8, // Steel Grey
    0xFFE2E8F0, // Platinum
  ];

  /// Curated set of lifestyle / habit icons.
  static const List<Map<String, dynamic>> availableIcons = [
    {'key': 'sport', 'icon': Icons.fitness_center_rounded, 'label': 'Sport'},
    {'key': 'guitar', 'icon': Icons.music_note_rounded, 'label': 'Guitar'},
    {'key': 'no_phone', 'icon': Icons.phonelink_erase_rounded, 'label': 'No Doomscroll'},
    {'key': 'book', 'icon': Icons.menu_book_rounded, 'label': 'Reading'},
    {'key': 'code', 'icon': Icons.code_rounded, 'label': 'Coding'},
    {'key': 'water', 'icon': Icons.water_drop_rounded, 'label': 'Water'},
    {'key': 'meditation', 'icon': Icons.self_improvement_rounded, 'label': 'Meditation'},
    {'key': 'bed', 'icon': Icons.bedtime_rounded, 'label': 'Sleep'},
    {'key': 'bike', 'icon': Icons.directions_bike_rounded, 'label': 'Cycling'},
    {'key': 'run', 'icon': Icons.directions_run_rounded, 'label': 'Running'},
    {'key': 'food', 'icon': Icons.restaurant_rounded, 'label': 'Nutrition'},
    {'key': 'heart', 'icon': Icons.favorite_rounded, 'label': 'Health'},
    {'key': 'brain', 'icon': Icons.psychology_rounded, 'label': 'Mindset'},
    {'key': 'art', 'icon': Icons.palette_rounded, 'label': 'Creative'},
    {'key': 'clean', 'icon': Icons.cleaning_services_rounded, 'label': 'Clean'},
    {'key': 'money', 'icon': Icons.savings_rounded, 'label': 'Finance'},
  ];

  /// Get the IconData corresponding to an iconKey.
  static IconData getIcon(String iconKey) {
    final entry = availableIcons.firstWhere(
      (element) => element['key'] == iconKey,
      orElse: () => {'key': 'sport', 'icon': Icons.fitness_center_rounded},
    );
    return entry['icon'] as IconData;
  }
}
