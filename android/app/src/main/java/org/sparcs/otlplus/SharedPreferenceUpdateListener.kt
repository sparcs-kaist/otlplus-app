package org.sparcs.otlplus

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

class SharedPreferenceUpdateListener(context: Context) {
    private val sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    private val appWidgetManager = AppWidgetManager.getInstance(context)
    private val componentName = ComponentName(context, TimetableWidget::class.java)

    private val preferenceChangeListener = SharedPreferences.OnSharedPreferenceChangeListener { _, _ ->
        val timetableIntent = Intent(context, TimetableWidget::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val componentName = ComponentName(context, TimetableWidget::class.java)
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetManager.getAppWidgetIds(componentName))
        }
        context.sendBroadcast(timetableIntent)

        val nextLectureIntent = Intent(context, NextLectureWidget::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val componentName = ComponentName(context, NextLectureWidget::class.java)
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetManager.getAppWidgetIds(componentName))
        }
        context.sendBroadcast(nextLectureIntent)
    }

    fun register() {
        sharedPreferences.registerOnSharedPreferenceChangeListener(preferenceChangeListener)
    }

    fun unregister() {
        sharedPreferences.unregisterOnSharedPreferenceChangeListener(preferenceChangeListener)
    }
}