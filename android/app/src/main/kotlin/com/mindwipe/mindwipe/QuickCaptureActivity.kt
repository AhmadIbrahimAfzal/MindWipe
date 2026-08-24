package com.mindwipe.mindwipe

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.ImageView
import android.widget.Toast
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

/**
 * Floating direct-input activity launched directly from the Home Screen widget.
 *
 * 🧠 LEARN:
 * - Opens as a lightweight transparent modal over the Android home screen.
 * - Immediately requests focus and brings up the soft keyboard.
 * - Inserts the captured thought into the Drift SQLite database file (`mindwipe.db`)
 *   with `is_dirty = 1` so when Flutter/SyncService runs, it automatically pushes to Supabase.
 * - Updates Home Screen widgets and exits in under 100ms.
 */
class QuickCaptureActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_quick_capture)

        val input = findViewById<EditText>(R.id.quick_capture_input)
        val submitBtn = findViewById<ImageView>(R.id.quick_capture_submit)
        val scrim = findViewById<View>(R.id.quick_capture_scrim)

        // Close when tapping outside the card
        scrim.setOnClickListener {
            closeKeyboard(input)
            finish()
        }

        // Prevent click on the card from closing
        findViewById<View>(R.id.quick_capture_card).setOnClickListener { /* Consume click */ }

        // Automatically open keyboard
        input.requestFocus()
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_VISIBLE)
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.showSoftInput(input, InputMethodManager.SHOW_IMPLICIT)

        // Submit action
        val doSubmit = {
            val text = input.text.toString().trim()
            if (text.isNotEmpty()) {
                saveThought(text)
                Toast.makeText(this, "Thought captured ✨", Toast.LENGTH_SHORT).show()
            }
            closeKeyboard(input)
            finish()
        }

        submitBtn.setOnClickListener { doSubmit() }

        input.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                doSubmit()
                true
            } else {
                false
            }
        }
    }

    private fun closeKeyboard(view: View) {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.hideSoftInputFromWindow(view.windowToken, 0)
    }

    private fun saveThought(title: String) {
        val id = UUID.randomUUID().toString()
        val nowMillis = System.currentTimeMillis()
        val df = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        val isoDate = df.format(Date(nowMillis))

        // 1. Insert into Drift SQLite database
        try {
            // In Flutter, app documents are at /data/data/<pkg>/app_flutter
            val dbFolder = File(filesDir.parentFile, "app_flutter")
            if (!dbFolder.exists()) dbFolder.mkdirs()
            val dbFile = File(dbFolder, "mindwipe.db")

            val db = SQLiteDatabase.openOrCreateDatabase(dbFile, null)
            // Create table if not exists just in case
            db.execSQL(
                "CREATE TABLE IF NOT EXISTS tasks (" +
                "id TEXT NOT NULL PRIMARY KEY, " +
                "title TEXT NOT NULL, " +
                "created_at INTEGER NOT NULL, " +
                "is_completed INTEGER NOT NULL DEFAULT 0, " +
                "completed_at INTEGER, " +
                "updated_at INTEGER NOT NULL, " +
                "is_dirty INTEGER NOT NULL DEFAULT 1, " +
                "is_deleted INTEGER NOT NULL DEFAULT 0)"
            )

            val values = ContentValues().apply {
                put("id", id)
                put("title", title)
                put("created_at", nowMillis)
                put("is_completed", 0)
                put("updated_at", nowMillis)
                put("is_dirty", 1)
                put("is_deleted", 0)
            }
            db.insertWithOnConflict("tasks", null, values, SQLiteDatabase.CONFLICT_REPLACE)
            db.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 2. Update home_widget shared preferences
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val currentCountStr = prefs.getString("flutter.pending_count", "0") ?: "0"
            val count = (currentCountStr.toIntOrNull() ?: 0) + 1

            prefs.edit()
                .putString("flutter.top_task_title", title)
                .putString("flutter.top_task_id", id)
                .putString("flutter.pending_count", count.toString())
                .apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }

        // 3. Broadcast widget refresh
        val appWidgetManager = AppWidgetManager.getInstance(this)
        val dumpComponent = ComponentName(this, BrainDumpWidgetReceiver::class.java)
        val dumpIds = appWidgetManager.getAppWidgetIds(dumpComponent)
        val intent = Intent(this, BrainDumpWidgetReceiver::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, dumpIds)
        }
        sendBroadcast(intent)

        val microComponent = ComponentName(this, MicroTaskWidgetReceiver::class.java)
        val microIds = appWidgetManager.getAppWidgetIds(microComponent)
        val microIntent = Intent(this, MicroTaskWidgetReceiver::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, microIds)
        }
        sendBroadcast(microIntent)
    }
}
