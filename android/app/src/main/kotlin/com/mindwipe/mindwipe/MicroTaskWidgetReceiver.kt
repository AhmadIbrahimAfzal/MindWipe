package com.mindwipe.mindwipe

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Native Android Home Screen Widget for Floating Micro-Task Pill (MindWipe Pro feature).
 *
 * 🧠 LEARN:
 * - Free users: Displays a stylish lock badge ("⭐ Pro — Unlock in MindWipe").
 * - Pro users: Displays the live top active thought.
 * - Tapping opens the app directly to view tasks or activate Pro.
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
                val isPremiumStr = widgetData.getString("flutter.is_premium", null)
                    ?: widgetData.getString("is_premium", "false") ?: "false"
                val isPremium = isPremiumStr == "true"

                if (isPremium) {
                    val topTaskTitle = widgetData.getString("flutter.top_task_title", null)
                        ?: widgetData.getString("top_task_title", "All clear ✨") ?: "All clear ✨"
                    setTextViewText(R.id.micro_task_title, topTaskTitle)
                } else {
                    setTextViewText(R.id.micro_task_title, "⭐ MindWipe Pro — Tap to Unlock")
                }

                // Tapping opens the main app
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                val openAppPending = PendingIntent.getActivity(
                    context,
                    201,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.micro_widget_root, openAppPending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
