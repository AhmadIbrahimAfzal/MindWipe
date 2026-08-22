package com.mindwipe.mindwipe

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Native Android Home Screen Widget for Floating Micro-Task Pill.
 *
 * Displays top active thought in a floating pill container on launcher screen.
 */
class MicroTaskWidgetReceiver : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.micro_task_widget_layout).apply {
                val topTaskTitle = widgetData.getString("top_task_title", "All clear") ?: "All clear"
                setTextViewText(R.id.micro_task_title, topTaskTitle)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
