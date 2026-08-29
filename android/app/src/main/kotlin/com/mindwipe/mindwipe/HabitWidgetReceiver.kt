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
import android.util.Log
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Native Android Home Screen Widget for Habit Tracking (HabitKit Aesthetic).
 *
 * Features:
 * - Displays primary habit name, description, and aesthetic tinted Material icon badge.
 * - Renders a sleek HabitKit dot-matrix consistency grid.
 * - Directly toggles today's completion from the Home Screen via SQLite.
 * - Full 2-way sync with in-app Flutter modifications (missed day toggles, creation, editing).
 */
class HabitWidgetReceiver : HomeWidgetProvider() {

    companion object {
        const val TAG = "HabitWidget"
        const val ACTION_TOGGLE_HABIT = "com.mindwipe.mindwipe.ACTION_TOGGLE_HABIT"
        const val EXTRA_HABIT_ID = "extra_habit_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "onReceive: action=${intent.action}")
        if (intent.action == ACTION_TOGGLE_HABIT) {
            val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: ""
            Log.d(TAG, "Toggle habit: $habitId")
            toggleHabitInDatabase(context, habitId)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate: ${appWidgetIds.size} widgets")
        appWidgetIds.forEach { widgetId ->
            updateSingleWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun getPrefString(prefs: SharedPreferences, key: String, default: String? = null): String? {
        val withPrefix = prefs.getString("flutter.$key", null)
        if (!withPrefix.isNullOrEmpty()) return withPrefix
        val withoutPrefix = prefs.getString(key, null)
        if (!withoutPrefix.isNullOrEmpty()) return withoutPrefix
        return default
    }

    private fun updateSingleWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        var habitId = getPrefString(widgetData, "primary_habit_id", "") ?: ""
        var name = getPrefString(widgetData, "primary_habit_name", null)
        var description = getPrefString(widgetData, "primary_habit_description", null)
        var iconKey = getPrefString(widgetData, "primary_habit_icon_key", "sport") ?: "sport"
        var colorHexStr = getPrefString(widgetData, "primary_habit_color", "#8B5CF6") ?: "#8B5CF6"
        var isCompletedToday = getPrefString(widgetData, "primary_habit_is_completed_today", "false") == "true"
        var matrixData = getPrefString(widgetData, "primary_habit_matrix_data", "") ?: ""

        // Fallback: If SharedPreferences is empty or unpopulated, query SQLite directly
        if (name == null || habitId.isEmpty() || matrixData.isEmpty()) {
            Log.d(TAG, "SharedPrefs empty/incomplete, loading from SQLite")
            val dbData = loadFirstHabitFromDatabase(context)
            if (dbData != null) {
                habitId = dbData.id
                name = dbData.name
                description = dbData.description
                iconKey = dbData.iconKey
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
            Color.parseColor("#8B5CF6")
        }

        val views = RemoteViews(context.packageName, R.layout.habit_widget_layout).apply {
            setTextViewText(R.id.habit_widget_title, name)
            setTextViewText(R.id.habit_widget_subtitle, description ?: "")

            // Render aesthetic icon badge matching Flutter's HabitCard
            val iconBadgeBitmap = renderIconBadgeBitmap(context, iconKey, habitColor)
            setImageViewBitmap(R.id.habit_widget_icon, iconBadgeBitmap)

            // Checkmark visual state
            if (isCompletedToday) {
                setInt(R.id.habit_widget_check_btn, "setBackgroundResource", R.drawable.widget_check_active)
            } else {
                setInt(R.id.habit_widget_check_btn, "setBackgroundResource", R.drawable.widget_check_inactive)
            }

            // Render dot-matrix grid bitmap
            val matrixBitmap = renderMatrixBitmap(matrixData, habitColor)
            setImageViewBitmap(R.id.habit_widget_matrix_image, matrixBitmap)

            // 1. Tick button toggles today's habit
            val toggleIntent = Intent(context, HabitWidgetReceiver::class.java).apply {
                action = ACTION_TOGGLE_HABIT
                putExtra(EXTRA_HABIT_ID, habitId)
                data = Uri.parse("mindwipe://habit/$widgetId/$habitId/${System.currentTimeMillis()}")
            }
            val togglePending = PendingIntent.getBroadcast(
                context,
                widgetId + 2000,
                toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
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
        Log.d(TAG, "Widget $widgetId updated: name=$name, completed=$isCompletedToday, matrixLen=${matrixData.length}")
    }

    /**
     * Renders a 44dp icon badge bitmap with a 16% alpha tinted squircle background
     * and a centered Material vector icon in 100% habitColor — pixel-identical to the in-app HabitCard.
     */
    private fun renderIconBadgeBitmap(context: Context, iconKey: String, habitColor: Int): Bitmap {
        val size = 132 // 44dp @ 3x
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // 1. Background squircle: 16% alpha (0x29) of habitColor
        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(
                41, // ~16% alpha
                Color.red(habitColor),
                Color.green(habitColor),
                Color.blue(habitColor)
            )
        }
        val cornerRadius = size * 0.32f // 14dp radius proportionally
        canvas.drawRoundRect(RectF(0f, 0f, size.toFloat(), size.toFloat()), cornerRadius, cornerRadius, bgPaint)

        // 2. Center vector icon: tinted with 100% habitColor
        val drawableRes = mapIconKeyToDrawableRes(iconKey)
        val drawable = ContextCompat.getDrawable(context, drawableRes)
        if (drawable != null) {
            drawable.setTint(habitColor)
            val iconSize = (size * 0.52f).toInt() // 22dp @ 3x
            val left = (size - iconSize) / 2
            val top = (size - iconSize) / 2
            drawable.setBounds(left, top, left + iconSize, top + iconSize)
            drawable.draw(canvas)
        }

        return bitmap
    }

    private fun renderMatrixBitmap(matrixData: String, activeColor: Int): Bitmap {
        val numCols = 18
        val numRows = 6
        val width = 720
        val height = 240

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        val cellSpacing = 6f
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

                paint.color = if (isCompleted) {
                    activeColor
                } else {
                    Color.argb(20, 255, 255, 255)
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
        val iconKey: String,
        val colorHex: String,
        val isCompletedToday: Boolean,
        val matrixData: String
    )

    private fun findDatabaseFile(context: Context): File? {
        val primaryDb = File(context.filesDir, "mindwipe.db")
        if (primaryDb.exists()) return primaryDb

        val fallbackDb = File(File(context.filesDir.parentFile, "app_flutter"), "mindwipe.db")
        if (fallbackDb.exists()) return fallbackDb

        Log.w(TAG, "Database not found at ${primaryDb.path} or ${fallbackDb.path}")
        return null
    }

    private fun loadFirstHabitFromDatabase(context: Context): HabitDbData? {
        try {
            val dbFile = findDatabaseFile(context) ?: return null
            val db = SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READONLY)
            val cursor = db.rawQuery(
                "SELECT id, name, description, icon_key, color_value FROM habits WHERE is_deleted = 0 ORDER BY order_index LIMIT 1",
                null
            )
            if (cursor.moveToFirst()) {
                val id = cursor.getString(0)
                val name = cursor.getString(1)
                val description = cursor.getString(2) ?: ""
                val iconKey = cursor.getString(3) ?: "sport"
                val colorVal = cursor.getInt(4)

                cursor.close()

                val colorHex = String.format("#%06X", (0xFFFFFF and colorVal))

                val df = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
                    timeZone = TimeZone.getDefault()
                }
                val todayStr = df.format(Date())

                // Load all active completions for this habit
                val completedDates = mutableSetOf<String>()
                val compCursor = db.rawQuery(
                    "SELECT date FROM habit_completions WHERE habit_id = ? AND is_deleted = 0",
                    arrayOf(id)
                )
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
                    iconKey = iconKey,
                    colorHex = colorHex,
                    isCompletedToday = isToday,
                    matrixData = flags.joinToString(",")
                )
            }
            cursor.close()
            db.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error loading habit from DB", e)
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

        try {
            val dbFile = findDatabaseFile(context)
            if (dbFile == null) {
                Log.e(TAG, "Cannot toggle: database file not found")
                return
            }

            val db = SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READWRITE)

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

            if (habitId.isEmpty()) {
                val hCursor = db.rawQuery(
                    "SELECT id FROM habits WHERE is_deleted = 0 ORDER BY order_index LIMIT 1",
                    null
                )
                if (hCursor.moveToFirst()) {
                    habitId = hCursor.getString(0)
                }
                hCursor.close()
            }

            var newCompletedStatus = true

            if (habitId.isNotEmpty()) {
                val completionId = "${habitId}_$dateStr"
                val cursor = db.rawQuery(
                    "SELECT is_deleted FROM habit_completions WHERE id = ?",
                    arrayOf(completionId)
                )
                if (cursor.moveToFirst()) {
                    val isDeleted = cursor.getInt(0)
                    if (isDeleted == 1) {
                        db.execSQL(
                            "UPDATE habit_completions SET is_deleted = 0, is_dirty = 1, updated_at = ? WHERE id = ?",
                            arrayOf<Any>(nowMillis, completionId)
                        )
                        newCompletedStatus = true
                    } else {
                        db.execSQL(
                            "UPDATE habit_completions SET is_deleted = 1, is_dirty = 1, updated_at = ? WHERE id = ?",
                            arrayOf<Any>(nowMillis, completionId)
                        )
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
                    db.insertWithOnConflict(
                        "habit_completions", null, values,
                        SQLiteDatabase.CONFLICT_REPLACE
                    )
                    newCompletedStatus = true
                }
                cursor.close()

                // Recalculate matrix data after toggle
                val completedDates = mutableSetOf<String>()
                val compCursor = db.rawQuery(
                    "SELECT date FROM habit_completions WHERE habit_id = ? AND is_deleted = 0",
                    arrayOf(habitId)
                )
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

                val matrixStr = flags.joinToString(",")
                val isTodayStr = if (newCompletedStatus) "true" else "false"

                // Update SharedPreferences (both with and without flutter. prefix for robust reading)
                val prefs = context.getSharedPreferences(
                    "FlutterSharedPreferences", Context.MODE_PRIVATE
                )
                prefs.edit()
                    .putString("flutter.primary_habit_id", habitId)
                    .putString("primary_habit_id", habitId)
                    .putString("flutter.primary_habit_is_completed_today", isTodayStr)
                    .putString("primary_habit_is_completed_today", isTodayStr)
                    .putString("flutter.primary_habit_matrix_data", matrixStr)
                    .putString("primary_habit_matrix_data", matrixStr)
                    .apply()

                Log.d(TAG, "Toggled: id=$completionId, completed=$newCompletedStatus, matrixLen=${matrixStr.length}")
            }
            db.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error toggling habit", e)
        }

        // Trigger immediate widget redraw
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val habitComponent = ComponentName(context, HabitWidgetReceiver::class.java)
        val habitIds = appWidgetManager.getAppWidgetIds(habitComponent)
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        onUpdate(context, appWidgetManager, habitIds, prefs)
    }

    private fun mapIconKeyToDrawableRes(key: String): Int {
        return when (key) {
            "sport" -> R.drawable.ic_habit_sport
            "guitar" -> R.drawable.ic_habit_guitar
            "no_phone" -> R.drawable.ic_habit_no_phone
            "book" -> R.drawable.ic_habit_book
            "code" -> R.drawable.ic_habit_code
            "water" -> R.drawable.ic_habit_water
            "meditation" -> R.drawable.ic_habit_meditation
            "bed" -> R.drawable.ic_habit_bed
            "bike" -> R.drawable.ic_habit_bike
            "run" -> R.drawable.ic_habit_run
            "food" -> R.drawable.ic_habit_food
            "heart" -> R.drawable.ic_habit_heart
            "brain" -> R.drawable.ic_habit_brain
            "art" -> R.drawable.ic_habit_art
            "clean" -> R.drawable.ic_habit_clean
            "money" -> R.drawable.ic_habit_money
            else -> R.drawable.ic_habit_bolt
        }
    }
}
