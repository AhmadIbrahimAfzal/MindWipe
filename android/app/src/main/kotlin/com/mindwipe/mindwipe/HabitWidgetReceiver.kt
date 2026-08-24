package com.mindwipe.mindwipe

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.database.sqlite.SQLiteDatabase
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Native Android Home Screen Widget for Habit Tracking (HabitKit Style).
 *
 * Features:
 * - Displays primary habit name, description, and icon symbol.
 * - Renders a sleek HabitKit dot-matrix consistency grid.
 * - Directly toggles today's completion from the Home Screen with immediate SQLite & UI update.
 */
class HabitWidgetReceiver : HomeWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_HABIT = "com.mindwipe.mindwipe.ACTION_TOGGLE_HABIT"
        const val EXTRA_HABIT_ID = "extra_habit_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_HABIT) {
            val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: ""
            toggleHabitInDatabase(context, habitId)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            var habitId = widgetData.getString("flutter.primary_habit_id", null)
                ?: widgetData.getString("primary_habit_id", "") ?: ""
            var name = widgetData.getString("flutter.primary_habit_name", null)
                ?: widgetData.getString("primary_habit_name", null)
            var description = widgetData.getString("flutter.primary_habit_description", null)
                ?: widgetData.getString("primary_habit_description", null)
            var iconSymbol = widgetData.getString("flutter.primary_habit_icon", null)
                ?: widgetData.getString("primary_habit_icon", "⚡") ?: "⚡"
            var colorHexStr = widgetData.getString("flutter.primary_habit_color", null)
                ?: widgetData.getString("primary_habit_color", "#FFB800") ?: "#FFB800"
            var isCompletedToday = widgetData.getString("flutter.primary_habit_is_completed_today", "false") == "true"
            var matrixData = widgetData.getString("flutter.primary_habit_matrix_data", "") ?: ""

            // Fallback: If SharedPreferences is empty, query SQLite directly
            if (name == null || habitId.isEmpty()) {
                val dbData = loadFirstHabitFromDatabase(context)
                if (dbData != null) {
                    habitId = dbData.id
                    name = dbData.name
                    description = dbData.description
                    iconSymbol = dbData.iconSymbol
                    colorHexStr = dbData.colorHex
                    isCompletedToday = dbData.isCompletedToday
                    matrixData = dbData.matrixData
                } else {
                    name = "Create a Habit"
                    description = "Open MindWipe to add your first ritual"
                }
            }

            val habitColor = try {
                Color.parseColor(colorHexStr)
            } catch (e: Exception) {
                Color.parseColor("#FFB800")
            }

            val views = RemoteViews(context.packageName, R.layout.habit_widget_layout).apply {
                setTextViewText(R.id.habit_widget_title, name)
                setTextViewText(R.id.habit_widget_subtitle, description ?: "")
                setTextViewText(R.id.habit_widget_icon, iconSymbol)

                // Checkmark state
                if (isCompletedToday) {
                    setInt(R.id.habit_widget_check_btn, "setBackgroundResource", R.drawable.widget_check_active)
                } else {
                    setInt(R.id.habit_widget_check_btn, "setBackgroundResource", R.drawable.widget_check_inactive)
                }

                // Render dot-matrix grid
                val matrixBitmap = renderMatrixBitmap(matrixData, habitColor)
                setImageViewBitmap(R.id.habit_widget_matrix_image, matrixBitmap)

                // 1. Direct Tick button click intent
                val toggleIntent = Intent(context, HabitWidgetReceiver::class.java).apply {
                    action = ACTION_TOGGLE_HABIT
                    putExtra(EXTRA_HABIT_ID, habitId)
                    data = Uri.parse("habit://$widgetId/$habitId")
                }
                val togglePending = PendingIntent.getBroadcast(
                    context,
                    widgetId + 2000,
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.habit_widget_check_btn, togglePending)

                // 2. Open app on widget body tap
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openAppPending = PendingIntent.getActivity(
                    context,
                    widgetId + 3000,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.habit_widget_root, openAppPending)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun renderMatrixBitmap(matrixData: String, activeColor: Int): Bitmap {
        val numCols = 18
        val numRows = 6
        val width = 540
        val height = 180

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        val cellSpacing = 8f
        val cellWidth = (width - (numCols - 1) * cellSpacing) / numCols
        val cellHeight = (height - (numRows - 1) * cellSpacing) / numRows
        val radius = cellWidth * 0.28f

        val values = if (matrixData.isNotEmpty()) matrixData.split(",") else emptyList()

        for (col in 0 until numCols) {
            for (row in 0 until numRows) {
                val index = col * numRows + row
                val isCompleted = if (index < values.size) values[index] == "1" else false

                val left = col * (cellWidth + cellSpacing)
                val top = row * (cellHeight + cellSpacing)
                val rect = RectF(left, top, left + cellWidth, top + cellHeight)

                if (isCompleted) {
                    paint.color = activeColor
                } else {
                    paint.color = Color.argb(18, 255, 255, 255)
                }

                canvas.drawRoundRect(rect, radius, radius, paint)
            }
        }

        return bitmap
    }

    private data class HabitDbData(
        val id: String,
        val name: String,
        val description: String,
        val iconSymbol: String,
        val colorHex: String,
        val isCompletedToday: Boolean,
        val matrixData: String
    )

    private fun loadFirstHabitFromDatabase(context: Context): HabitDbData? {
        try {
            val dbFolder = File(context.filesDir.parentFile, "app_flutter")
            val dbFile = File(dbFolder, "mindwipe.db")
            if (!dbFile.exists()) return null

            val db = SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READONLY)
            val cursor = db.rawQuery("SELECT id, name, description, icon_key, color_value FROM habits WHERE is_deleted = 0 ORDER BY order_index LIMIT 1", null)
            if (cursor.moveToFirst()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1)
                val description = cursor.getString(2) ?: ""
                val iconKey = cursor.getString(3) ?: "sport"
                val colorVal = cursor.getInt(4)

                cursor.close()

                val colorHex = String.format("#%06X", (0xFFFFFF and colorVal))
                val iconSymbol = mapIconKeyToSymbol(iconKey)

                val df = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
                    timeZone = TimeZone.getDefault()
                }
                val todayStr = df.format(Date())

                // Load completions
                val completedDates = mutableSetOf<String>()
                val compCursor = db.rawQuery("SELECT date FROM habit_completions WHERE habit_id = ? AND is_deleted = 0", arrayOf(id))
                while (compCursor.moveToNext()) {
                    completedDates.add(compCursor.getString(0))
                }
                compCursor.close()
                db.close()

                val isToday = completedDates.contains(todayStr)

                // Build 18x6 matrix data
                val cal = Calendar.getInstance()
                val totalCells = 18 * 6
                val flags = mutableListOf<String>()

                for (col in 0 until 18) {
                    for (row in 0 until 6) {
                        val cellIndex = col * 6 + row
                        val daysAgo = (totalCells - 1) - cellIndex
                        cal.time = Date()
                        cal.add(Calendar.DAY_OF_YEAR, -daysAgo)
                        val dStr = df.format(cal.time)
                        flags.add(if (completedDates.contains(dStr)) "1" else "0")
                    }
                }

                return HabitDbData(
                    id = id,
                    name = name,
                    description = description,
                    iconSymbol = iconSymbol,
                    colorHex = colorHex,
                    isCompletedToday = isToday,
                    matrixData = flags.joinToString(",")
                )
            }
            cursor.close()
            db.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }

    private fun toggleHabitInDatabase(context: Context, targetHabitId: String) {
        var habitId = targetHabitId

        val nowMillis = System.currentTimeMillis()
        val df = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
            timeZone = TimeZone.getDefault()
        }
        val dateStr = df.format(Date(nowMillis))

        var newCompletedStatus = true

        try {
            val dbFolder = File(context.filesDir.parentFile, "app_flutter")
            if (!dbFolder.exists()) dbFolder.mkdirs()
            val dbFile = File(dbFolder, "mindwipe.db")

            val db = SQLiteDatabase.openOrCreateDatabase(dbFile, null)
            db.execSQL(
                "CREATE TABLE IF NOT EXISTS habit_completions (" +
                "id TEXT NOT NULL PRIMARY KEY, " +
                "habit_id TEXT NOT NULL, " +
                "date TEXT NOT NULL, " +
                "completed_at INTEGER NOT NULL, " +
                "created_at INTEGER NOT NULL, " +
                "updated_at INTEGER NOT NULL, " +
                "is_dirty INTEGER NOT NULL DEFAULT 1, " +
                "is_deleted INTEGER NOT NULL DEFAULT 0)"
            )

            // If habitId is empty, get first habit from DB
            if (habitId.isEmpty()) {
                val hCursor = db.rawQuery("SELECT id FROM habits WHERE is_deleted = 0 ORDER BY order_index LIMIT 1", null)
                if (hCursor.moveToFirst()) {
                    habitId = hCursor.getString(0)
                }
                hCursor.close()
            }

            if (habitId.isNotEmpty()) {
                val completionId = "${habitId}_$dateStr"
                val cursor = db.rawQuery("SELECT is_deleted FROM habit_completions WHERE id = ?", arrayOf(completionId))
                if (cursor.moveToFirst()) {
                    val isDeleted = cursor.getInt(0)
                    if (isDeleted == 1) {
                        db.execSQL("UPDATE habit_completions SET is_deleted = 0, is_dirty = 1, updated_at = ? WHERE id = ?", arrayOf<Any>(nowMillis, completionId))
                        newCompletedStatus = true
                    } else {
                        db.execSQL("UPDATE habit_completions SET is_deleted = 1, is_dirty = 1, updated_at = ? WHERE id = ?", arrayOf<Any>(nowMillis, completionId))
                        newCompletedStatus = false
                    }
                } else {
                    val values = ContentValues().apply {
                        put("id", completionId)
                        put("habit_id", habitId)
                        put("date", dateStr)
                        put("completed_at", nowMillis)
                        put("created_at", nowMillis)
                        put("updated_at", nowMillis)
                        put("is_dirty", 1)
                        put("is_deleted", 0)
                    }
                    db.insertWithOnConflict("habit_completions", null, values, SQLiteDatabase.CONFLICT_REPLACE)
                    newCompletedStatus = true
                }
                cursor.close()

                // Recalculate matrix data
                val completedDates = mutableSetOf<String>()
                val compCursor = db.rawQuery("SELECT date FROM habit_completions WHERE habit_id = ? AND is_deleted = 0", arrayOf(habitId))
                while (compCursor.moveToNext()) {
                    completedDates.add(compCursor.getString(0))
                }
                compCursor.close()

                val cal = Calendar.getInstance()
                val totalCells = 18 * 6
                val flags = mutableListOf<String>()

                for (col in 0 until 18) {
                    for (row in 0 until 6) {
                        val cellIndex = col * 6 + row
                        val daysAgo = (totalCells - 1) - cellIndex
                        cal.time = Date()
                        cal.add(Calendar.DAY_OF_YEAR, -daysAgo)
                        val dStr = df.format(cal.time)
                        flags.add(if (completedDates.contains(dStr)) "1" else "0")
                    }
                }

                // Update SharedPreferences
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                prefs.edit()
                    .putString("flutter.primary_habit_id", habitId)
                    .putString("flutter.primary_habit_is_completed_today", if (newCompletedStatus) "true" else "false")
                    .putString("flutter.primary_habit_matrix_data", flags.joinToString(","))
                    .apply()
            }
            db.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // Trigger immediate widget redraw
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val habitComponent = ComponentName(context, HabitWidgetReceiver::class.java)
        val habitIds = appWidgetManager.getAppWidgetIds(habitComponent)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        onUpdate(context, appWidgetManager, habitIds, prefs)
    }

    private fun mapIconKeyToSymbol(key: String): String {
        return when (key) {
            "sport" -> "🏋️"
            "guitar" -> "🎸"
            "no_phone" -> "📵"
            "book" -> "📖"
            "code" -> "</>"
            "water" -> "💧"
            "meditation" -> "🧘"
            "bed" -> "🌙"
            "bike" -> "🚴"
            "run" -> "🏃"
            "food" -> "🥗"
            "heart" -> "❤️"
            "brain" -> "🧠"
            "art" -> "🎨"
            "clean" -> "✨"
            "money" -> "💰"
            else -> "⚡"
        }
    }
}
