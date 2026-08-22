package com.mindwipe.mindwipe

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Native Android Home Screen Widget for Quick Capture / Brain Dump Bar.
 *
 * 🧠 LEARN:
 * - Extends [HomeWidgetProvider] from the home_widget package.
 * - Reads top_task_title and pending_count from shared SharedPreferences.
 * - Updates the Android RemoteViews layout on the launcher screen.
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
                val pendingCount = widgetData.getString("pending_count", "0") ?: "0"
                val topTaskTitle = widgetData.getString("top_task_title", "No thoughts floating") ?: "No thoughts floating"

                setTextViewText(R.id.widget_pending_count, "$pendingCount thoughts")
                setTextViewText(R.id.widget_top_task, topTaskTitle)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
