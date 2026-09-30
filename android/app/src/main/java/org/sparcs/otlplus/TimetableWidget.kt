package org.sparcs.otlplus

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.annotation.SuppressLint
import android.util.TypedValue
import org.sparcs.otlplus.api.WidgetScheduleItem
import org.sparcs.otlplus.constants.BlockColor
import androidx.work.*
import java.util.concurrent.TimeUnit
import java.util.Calendar
import java.util.TimeZone
import android.os.Bundle
import org.sparcs.otlplus.api.TimetableData

/**
 * Implementation of App Widget functionality.
 */
class TimetableWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Schedule periodic update if not already scheduled
        schedulePeriodicUpdate(context)

        WidgetRefreshDispatcher.refresh(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        WidgetRefreshDispatcher.refresh(context)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        WidgetTimetablePreferences(context).delete(appWidgetIds)
    }

    override fun onRestored(context: Context, oldWidgetIds: IntArray, newWidgetIds: IntArray) {
        WidgetTimetablePreferences(context).restore(oldWidgetIds, newWidgetIds)
        WidgetRefreshDispatcher.refresh(context)
    }

    override fun onEnabled(context: Context) {
        schedulePeriodicUpdate(context)
    }

    private fun schedulePeriodicUpdate(context: Context) {
        // Schedule periodic update every 30 minutes
        val periodicWorkRequest = PeriodicWorkRequestBuilder<UpdateWidgetWorker>(30, TimeUnit.MINUTES)
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            "WidgetUpdateWork",
            ExistingPeriodicWorkPolicy.KEEP,
            periodicWorkRequest
        )
    }
}

data class WidgetGridRange(val days: Int, val startHour: Int, val endHour: Int)

internal fun widgetGridRange(
    items: List<WidgetScheduleItem>,
    calendar: Calendar = Calendar.getInstance(TimeZone.getTimeZone("Asia/Seoul")),
    visibleHours: Int = 8,
): WidgetGridRange {
    val hours = visibleHours.coerceIn(2, 16)
    val hour = calendar.get(Calendar.HOUR_OF_DAY)
    val day = (calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7
    val earliestToday = items.filter { it.day == day }.minOfOrNull { it.begin / 60 } ?: 9
    val preferredStart = when {
        hour < 9 -> if (earliestToday < 9) maxOf(earliestToday, hour - minOf(2, hours - 1)) else 9
        hour >= 15 -> hour - minOf(2, hours - 1)
        else -> maxOf(9, hour - (hours - 2))
    }
    val start = preferredStart.coerceIn(0, 24 - hours)
    return WidgetGridRange(if (items.any { it.day >= 5 }) 7 else 5, start, start + hours)
}

@SuppressLint("NewApi")
internal fun updateTimetableWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    timetableData: TimetableData,
) {
    val views = RemoteViews(context.packageName, R.layout.timetable_widget)
    views.setOnClickPendingIntent(R.id.timetable_start, widgetConfigurationIntent(context, appWidgetId))
    views.setContentDescription(R.id.timetable_start, context.getString(R.string.widget_choose_timetable))
    val height = appWidgetManager.getAppWidgetOptions(appWidgetId).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
    // Keep 36dp per hour. Resizing reveals more time instead of shrinking text.
    val hours = if (height > 0) ((height - 76) / 36).coerceIn(2, 16) else 8
    val range = widgetGridRange(timetableData.schedule, visibleHours = hours)
    val startMinute = range.startHour * 60
    val endMinute = range.endHour * 60
    val earlier = timetableData.schedule.count { it.begin < startMinute }
    val later = timetableData.schedule.count { it.end > endMinute }
    views.setTextViewText(R.id.widget_earlier, if (earlier > 0) context.getString(R.string.widget_earlier_events, earlier) else "")
    views.setTextViewText(R.id.widget_later, if (later > 0) context.getString(R.string.widget_later_events, later) else "")
    val columns = listOf(R.id.time_table_column_1, R.id.time_table_column_2, R.id.time_table_column_3,
        R.id.time_table_column_4, R.id.time_table_column_5, R.id.time_table_column_6, R.id.time_table_column_7)
    for ((day, column) in columns.withIndex()) {
        views.removeAllViews(column)
        views.setViewVisibility(column, if (day < range.days) android.view.View.VISIBLE else android.view.View.GONE)
        views.setViewLayoutHeight(column, (range.endHour - range.startHour) * 36f, TypedValue.COMPLEX_UNIT_DIP)
    }
    views.setViewVisibility(R.id.widget_day_sat, if (range.days == 7) android.view.View.VISIBLE else android.view.View.GONE)
    views.setViewVisibility(R.id.widget_day_sun, if (range.days == 7) android.view.View.VISIBLE else android.view.View.GONE)
    views.removeAllViews(R.id.widget_time_grid)
    for (minute in range.startHour * 60..range.endHour * 60 step 30) {
        val row = RemoteViews(context.packageName, R.layout.widget_time_row)
        row.setTextViewText(R.id.widget_hour, if (minute % 60 == 0) "${(minute / 60).let { if (it % 12 == 0) 12 else it % 12 }}" else "")
        for (day in 0 until range.days) {
            row.addView(R.id.widget_guidelines, RemoteViews(context.packageName,
                if (minute % 60 == 0) R.layout.widget_solid_guide else R.layout.widget_dotted_guide))
        }
        views.addView(R.id.widget_time_grid, row)
    }
    for (item in timetableData.schedule) {
        if (item.end <= startMinute || item.begin >= endMinute) continue
        val visibleBegin = maxOf(item.begin, startMinute)
        val visibleEnd = minOf(item.end, endMinute)
        val block = RemoteViews(context.packageName, BlockColor.blockColorsLayout[item.colorIndex])
        block.setTextViewText(R.id.timetable_block_lecture_name, item.name)
        block.setTextViewText(R.id.timetable_block_lecture_place, item.place)
        block.setViewLayoutHeight(R.id.timetable_block_root, (visibleEnd - visibleBegin) * 0.6f, TypedValue.COMPLEX_UNIT_DIP)
        block.setViewLayoutMargin(R.id.timetable_block_root, RemoteViews.MARGIN_TOP,
            (visibleBegin - startMinute) * 0.6f, TypedValue.COMPLEX_UNIT_DIP)
        views.addView(columns[item.day], block)
    }
    appWidgetManager.updateAppWidget(appWidgetId, views)
}
