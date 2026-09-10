package com.mindwipe.mindwipe

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

/**
 * Native Android Home Screen Widget for Quick Capture / Brain Dump Bar.
 *
 * Features:
 * - Tapping [+] triggers [QuickCaptureActivity] to pop up the keyboard immediately on the Home Screen.
 * - Tapping anywhere else on the card brings the existing Flutter app [MainActivity] to the foreground instantly.
 * - Rotates through all pending tasks automatically with a smooth fade & slide-up animation via ViewFlipper.
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
                // Read pending count (supports plain and flutter. prefix keys)
                val pendingCount = widgetData.getString("pending_count", null)
                    ?: widgetData.getString("flutter.pending_count", "0") ?: "0"

                // Parse all task titles
                val allTitlesJson = widgetData.getString("all_task_titles", null)
                    ?: widgetData.getString("flutter.all_task_titles", null)

                val taskTitles = mutableListOf<String>()
                if (!allTitlesJson.isNullOrEmpty()) {
                    try {
                        val jsonArray = JSONArray(allTitlesJson)
                        for (i in 0 until jsonArray.length()) {
                            val title = jsonArray.getString(i).trim()
                            if (title.isNotEmpty()) {
                                taskTitles.add(title)
                            }
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }

                if (taskTitles.isEmpty()) {
                    val topTitle = widgetData.getString("top_task_title", null)
                        ?: widgetData.getString("flutter.top_task_title", null)
                    if (!topTitle.isNullOrEmpty() && topTitle != "No thoughts floating") {
                        taskTitles.add(topTitle)
                    }
                }

                setTextViewText(R.id.widget_pending_count, "$pendingCount THOUGHTS FLOATING")

                // Populate ViewFlipper with tasks for smooth slide-up and fade rotation
                removeAllViews(R.id.widget_task_flipper)
                if (taskTitles.isEmpty()) {
                    val emptyItem = RemoteViews(context.packageName, R.layout.widget_flipper_item).apply {
                        setTextViewText(R.id.flipper_task_title, "No thoughts floating")
                    }
                    addView(R.id.widget_task_flipper, emptyItem)
                } else {
                    // Shuffled tasks rotate continuously with in/out animations
                    val shuffled = taskTitles.shuffled()
                    shuffled.forEach { title ->
                        val item = RemoteViews(context.packageName, R.layout.widget_flipper_item).apply {
                            setTextViewText(R.id.flipper_task_title, title)
                        }
                        addView(R.id.widget_task_flipper, item)
                    }
                }

                // 1. Tapping '+' opens direct QuickCapture keyboard activity
                val quickCaptureIntent = Intent(context, QuickCaptureActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_MULTIPLE_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val quickCapturePending = PendingIntent.getActivity(
                    context,
                    101,
                    quickCaptureIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_add_button, quickCapturePending)

                // 2. Tapping the widget body smoothly brings the existing app to foreground in 0ms
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
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
