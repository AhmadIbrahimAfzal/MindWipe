package com.mindwipe.mindwipe

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Native Android Home Screen Widget for Quick Capture / Brain Dump Bar.
 *
 * 🧠 LEARN:
 * - Tapping [+] triggers [QuickCaptureActivity] to pop up the keyboard immediately on the Home Screen.
 * - Tapping anywhere else on the card launches the main Flutter app [MainActivity].
 */
class BrainDumpWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.brain_dump_widget_layout).apply {
                // Read pending count & top task title (supports flutter. prefix and plain keys)
                val pendingCount = widgetData.getString("flutter.pending_count", null)
                    ?: widgetData.getString("pending_count", "0") ?: "0"
                val topTaskTitle = widgetData.getString("flutter.top_task_title", null)
                    ?: widgetData.getString("top_task_title", "No thoughts floating") ?: "No thoughts floating"

                setTextViewText(R.id.widget_pending_count, "$pendingCount THOUGHTS FLOATING")
                setTextViewText(R.id.widget_top_task, topTaskTitle)

                // 1. Tapping '+' opens direct QuickCapture keyboard activity
                val quickCaptureIntent = Intent(context, QuickCaptureActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val quickCapturePending = PendingIntent.getActivity(
                    context,
                    101,
                    quickCaptureIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_add_button, quickCapturePending)

                // 2. Tapping the widget body opens the main app
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                val openAppPending = PendingIntent.getActivity(
                    context,
                    102,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, openAppPending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
