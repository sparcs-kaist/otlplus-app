package org.sparcs.otlplus

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONException
import org.sparcs.otlplus.api.ApiLoadFailure
import org.sparcs.otlplus.api.ApiLoader
import org.sparcs.otlplus.api.TimetableData

class UpdateWidgetWorker(context: Context, params: WorkerParameters) : Worker(context, params) {

    override fun doWork(): Result {
        val apiLoader = ApiLoader(applicationContext)
        val appWidgetManager = AppWidgetManager.getInstance(applicationContext)

        return try {
            val source = WidgetTimetableSource(apiLoader::getSyncResult)
            val preferences = WidgetTimetablePreferences(applicationContext)
            val timetableIds = appWidgetManager.getAppWidgetIds(ComponentName(applicationContext, TimetableWidget::class.java)).toSet()
            val nextLectureIds = appWidgetManager.getAppWidgetIds(ComponentName(applicationContext, NextLectureWidget::class.java)).toSet()
            val widgetsBySelection = (timetableIds + nextLectureIds).groupBy(preferences::selectedId)
            var needsRetry = false
            val loaded = source.loadSelections(widgetsBySelection.keys)
            for ((selection, widgetIds) in widgetsBySelection) {
                val result = loaded.getValue(selection)
                val body = result.body
                if (body == null) {
                    if (result.failure != ApiLoadFailure.REJECTED) needsRetry = true
                    continue
                }
                val timetableData = TimetableData(body)
                for (widgetId in widgetIds) {
                    // Do not apply an old fetch after the user reconfigures this widget.
                    if (preferences.selectedId(widgetId) != selection) continue
                    if (widgetId in timetableIds) updateTimetableWidget(applicationContext, appWidgetManager, widgetId, timetableData)
                    else updateNextLectureWidget(applicationContext, appWidgetManager, widgetId, timetableData)
                }
            }
            if (needsRetry) return Result.retry()

            Result.success()
        } catch (_: JSONException) {
            Result.retry()
        }
    }

}
