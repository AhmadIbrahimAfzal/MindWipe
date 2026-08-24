import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindwipe/features/inbox/domain/entities/task.dart';
import 'package:mindwipe/features/habits/domain/entities/habit.dart';

/// Flutter service that syncs task state, habit state, and paywall tier to Android home screen widgets.
class WidgetSyncService {
  const WidgetSyncService();

  static const String appGroupId = 'group.com.mindwipe.mindwipe';
  static const String brainDumpWidgetReceiver = 'BrainDumpWidgetReceiver';
  static const String microTaskWidgetReceiver = 'MicroTaskWidgetReceiver';
  static const String habitWidgetReceiver = 'HabitWidgetReceiver';

  /// Syncs current list of tasks and subscription tier to SharedPreferences and updates widgets.
  Future<void> updateWidgets(List<Task> tasks, {bool? isPremium}) async {
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
    final topTask = pendingTasks.isNotEmpty ? pendingTasks.first : null;

    // Check subscription status if not explicitly passed
    bool premium = isPremium ?? false;
    if (isPremium == null) {
      final prefs = await SharedPreferences.getInstance();
      premium = prefs.getBool('mindwipe_is_premium') ?? false;
    }

    // Save data for native widgets to read
    await HomeWidget.saveWidgetData(
      'top_task_title',
      topTask?.title ?? 'No thoughts floating',
    );
    await HomeWidget.saveWidgetData(
      'top_task_id',
      topTask?.id ?? '',
    );
    await HomeWidget.saveWidgetData(
      'pending_count',
      '${pendingTasks.length}',
    );
    await HomeWidget.saveWidgetData(
      'is_premium',
      premium ? 'true' : 'false',
    );

    // Trigger update broadcasts to force Android widget redraw
    await HomeWidget.updateWidget(
      name: 'BrainDumpWidgetProvider',
      androidName: brainDumpWidgetReceiver,
    );
    await HomeWidget.updateWidget(
      name: 'MicroTaskWidgetProvider',
      androidName: microTaskWidgetReceiver,
    );
  }

  /// Syncs the primary active habit to the Android Home Screen Habit Widget.
  Future<void> updateHabitWidget(List<Habit> habits) async {
    if (habits.isEmpty) {
      await HomeWidget.saveWidgetData('primary_habit_name', 'No Habit');
      await HomeWidget.saveWidgetData('primary_habit_description', 'Tap to create your first ritual');
      await HomeWidget.saveWidgetData('primary_habit_icon', '⚡');
      await HomeWidget.saveWidgetData('primary_habit_color', '#8B5CF6');
      await HomeWidget.saveWidgetData('primary_habit_is_completed_today', 'false');
      await HomeWidget.saveWidgetData('primary_habit_matrix_data', '');
      await HomeWidget.updateWidget(
        name: 'HabitWidgetProvider',
        androidName: habitWidgetReceiver,
      );
      return;
    }

    final habit = habits.first;
    final isCompletedToday = habit.isCompletedToday();

    // Format 18 weeks x 6 rows matrix data
    final today = DateTime.now();
    final totalCells = 18 * 6;
    final matrixFlags = <String>[];

    for (int col = 0; col < 18; col++) {
      for (int row = 0; row < 6; row++) {
        final cellIndex = col * 6 + row;
        final daysAgo = (totalCells - 1) - cellIndex;
        final date = today.subtract(Duration(days: daysAgo));
        final year = date.year.toString().padLeft(4, '0');
        final month = date.month.toString().padLeft(2, '0');
        final day = date.day.toString().padLeft(2, '0');
        final dateStr = '$year-$month-$day';

        matrixFlags.add(habit.completedDates.contains(dateStr) ? '1' : '0');
      }
    }

    final colorHex = '#${habit.colorValue.toRadixString(16).padLeft(8, '0').substring(2)}';

    // Map icon key to emoji / display symbol for widget
    String iconSymbol = '⚡';
    switch (habit.iconKey) {
      case 'sport':
        iconSymbol = '🏋️';
        break;
      case 'guitar':
        iconSymbol = '🎸';
        break;
      case 'no_phone':
        iconSymbol = '📵';
        break;
      case 'book':
        iconSymbol = '📖';
        break;
      case 'code':
        iconSymbol = '</>';
        break;
      case 'water':
        iconSymbol = '💧';
        break;
      case 'meditation':
        iconSymbol = '🧘';
        break;
      case 'bed':
        iconSymbol = '🌙';
        break;
      case 'bike':
        iconSymbol = '🚴';
        break;
      case 'run':
        iconSymbol = '🏃';
        break;
      case 'food':
        iconSymbol = '🥗';
        break;
      case 'heart':
        iconSymbol = '❤️';
        break;
      case 'brain':
        iconSymbol = '🧠';
        break;
      case 'art':
        iconSymbol = '🎨';
        break;
      case 'clean':
        iconSymbol = '✨';
        break;
      case 'money':
        iconSymbol = '💰';
        break;
    }

    await HomeWidget.saveWidgetData('primary_habit_id', habit.id);
    await HomeWidget.saveWidgetData('primary_habit_name', habit.name);
    await HomeWidget.saveWidgetData('primary_habit_description', habit.description);
    await HomeWidget.saveWidgetData('primary_habit_icon', iconSymbol);
    await HomeWidget.saveWidgetData('primary_habit_color', colorHex);
    await HomeWidget.saveWidgetData(
      'primary_habit_is_completed_today',
      isCompletedToday ? 'true' : 'false',
    );
    await HomeWidget.saveWidgetData(
      'primary_habit_matrix_data',
      matrixFlags.join(','),
    );

    await HomeWidget.updateWidget(
      name: 'HabitWidgetProvider',
      androidName: habitWidgetReceiver,
    );
  }
}
