import 'package:home_widget/home_widget.dart';
import 'package:mindwipe/features/inbox/domain/entities/task.dart';

/// Flutter service that syncs task state to Android home screen widgets.
///
/// 🧠 LEARN:
/// 1. Home screen widgets live in native Kotlin/Android code and cannot directly
///    read Flutter's memory or Drift SQLite database.
/// 2. We use [HomeWidget.saveWidgetData] to write key-value data into shared
///    Android SharedPreferences.
/// 3. Calling [HomeWidget.updateWidget] triggers native BroadcastReceivers,
///    telling Android to repaint the home screen widgets with fresh data.
class WidgetSyncService {
  const WidgetSyncService();

  static const String appGroupId = 'group.com.mindwipe.mindwipe';
  static const String brainDumpWidgetReceiver = 'BrainDumpWidgetReceiver';
  static const String microTaskWidgetReceiver = 'MicroTaskWidgetReceiver';

  /// Syncs current list of tasks to SharedPreferences and updates widgets.
  Future<void> updateWidgets(List<Task> tasks) async {
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList();
    final topTask = pendingTasks.isNotEmpty ? pendingTasks.first : null;

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
}
