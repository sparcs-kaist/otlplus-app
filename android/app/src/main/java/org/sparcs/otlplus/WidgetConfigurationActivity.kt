package org.sparcs.otlplus

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import java.util.concurrent.Executors
import org.sparcs.otlplus.api.ApiLoader
import org.sparcs.otlplus.api.TimetableData

/** Shared native configuration for both Android widget providers. */
class WidgetConfigurationActivity : Activity() {
    private val executor = Executors.newSingleThreadExecutor()
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var selectedId = 0
    private var isTimetable = false
    private var semester: WidgetSemester? = null
    private var options = emptyList<WidgetTimetableOption>()
    private lateinit var status: TextView
    private lateinit var list: ListView
    private lateinit var save: Button
    private lateinit var retry: Button
    private val preferences by lazy { WidgetTimetablePreferences(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val provider = AppWidgetManager.getInstance(this).getAppWidgetInfo(widgetId)?.provider
        if (provider?.packageName != packageName ||
            provider.className !in listOf(TimetableWidget::class.java.name, NextLectureWidget::class.java.name)) {
            finish()
            return
        }
        isTimetable = provider.className == TimetableWidget::class.java.name
        selectedId = savedInstanceState?.getInt("selectedId") ?: preferences.selectedId(widgetId)
        title = getString(R.string.widget_choose_timetable)
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val padding = (24 * resources.displayMetrics.density).toInt()
            setPadding(padding, padding, padding, padding)
        }
        status = TextView(this).apply { textSize = 18f }
        list = ListView(this).apply { choiceMode = ListView.CHOICE_MODE_SINGLE }
        save = Button(this).apply {
            setText(R.string.widget_save)
            setOnClickListener { saveSelection() }
        }
        retry = Button(this).apply {
            setText(R.string.widget_retry)
            setOnClickListener { loadOptions() }
        }
        container.addView(status)
        container.addView(list, LinearLayout.LayoutParams(-1, 0, 1f))
        container.addView(retry)
        container.addView(save)
        container.addView(Button(this).apply {
            setText(R.string.widget_cancel)
            setOnClickListener { finish() }
        })
        setContentView(container)
        loadOptions()
    }

    private fun busy() {
        status.setText(R.string.widget_loading)
        list.isEnabled = false
        save.isEnabled = false
        retry.visibility = View.GONE
    }

    private fun error() {
        status.setText(R.string.widget_load_failed)
        list.isEnabled = true
        save.isEnabled = options.isNotEmpty()
        retry.visibility = View.VISIBLE
    }

    private fun loadOptions() {
        busy()
        executor.execute {
            try {
                val source = WidgetTimetableSource(ApiLoader(applicationContext)::getSyncResult)
                val current = source.currentSemester().first ?: error("semester unavailable")
                val tables = source.options(current).first ?: error("timetables unavailable")
                runOnUiThread {
                    if (isFinishing || isDestroyed) return@runOnUiThread
                    semester = current
                    options = listOf(WidgetTimetableOption(0, getString(R.string.widget_my_timetable))) + tables
                    // Keep an existing selection even if it belongs to a past term.
                    if (selectedId > 0 && options.none { it.id == selectedId }) {
                        options = options + WidgetTimetableOption(selectedId, getString(R.string.widget_previous_timetable))
                    }
                    list.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_single_choice,
                        options.map { it.name.ifBlank { getString(R.string.widget_unnamed_timetable) } })
                    list.setItemChecked(options.indexOfFirst { it.id == selectedId }, true)
                    list.setOnItemClickListener { _, _, position, _ -> selectedId = options[position].id }
                    list.isEnabled = true
                    save.isEnabled = true
                    status.setText(R.string.widget_choose_timetable)
                }
            } catch (_: Exception) {
                runOnUiThread { if (!isFinishing && !isDestroyed) error() }
            }
        }
    }

    private fun saveSelection() {
        val id = selectedId
        busy()
        executor.execute {
            try {
                val source = WidgetTimetableSource(ApiLoader(applicationContext)::getSyncResult)
                val body = source.timetable(id, semester).body ?: error("timetable unavailable")
                val table = TimetableData(body)
                runOnUiThread {
                    if (isFinishing || isDestroyed) return@runOnUiThread
                    val manager = AppWidgetManager.getInstance(this)
                    if (manager.getAppWidgetInfo(widgetId) == null) { finish(); return@runOnUiThread }
                    if (!preferences.save(widgetId, id)) { error(); return@runOnUiThread }
                    if (isTimetable) updateTimetableWidget(this, manager, widgetId, table)
                    else updateNextLectureWidget(this, manager, widgetId, table)
                    // Configuration activities must render the initial widget themselves.
                    sendBroadcast(Intent(this, if (isTimetable) TimetableWidget::class.java else NextLectureWidget::class.java)
                        .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                        .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId)))
                    setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
                    finish()
                }
            } catch (_: Exception) {
                runOnUiThread { if (!isFinishing && !isDestroyed) error() }
            }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putInt("selectedId", selectedId)
        super.onSaveInstanceState(outState)
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}
