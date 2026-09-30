package org.sparcs.otlplus

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.Intent
import android.net.Uri

internal class WidgetTimetablePreferences internal constructor(private val preferences: SharedPreferences) {
    constructor(context: Context) : this(context.getSharedPreferences("widget_timetables", Context.MODE_PRIVATE))
    fun selectedId(widgetId: Int): Int = preferences.getInt("timetable_$widgetId", 0)
    fun save(widgetId: Int, timetableId: Int): Boolean = preferences.edit()
        .putInt("timetable_$widgetId", timetableId).commit()
    fun delete(widgetIds: IntArray) {
        preferences.edit().apply {
            widgetIds.forEach { remove("timetable_$it") }
        }.apply()
    }
    fun restore(oldIds: IntArray, newIds: IntArray) {
        // Read all values before writing: old/new IDs may overlap.
        val selections = oldIds.map(::selectedId)
        preferences.edit().apply {
            oldIds.forEach { remove("timetable_$it") }
            newIds.forEachIndexed { index, id -> putInt("timetable_$id", selections[index]) }
        }.apply()
    }
}

internal fun widgetConfigurationIntent(context: Context, widgetId: Int): PendingIntent {
    val intent = Intent(context, WidgetConfigurationActivity::class.java)
        .setAction(AppWidgetManager.ACTION_APPWIDGET_CONFIGURE)
        .setData(Uri.parse("otl-widget://configure/$widgetId"))
        .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
    return PendingIntent.getActivity(context, widgetId, intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
}
