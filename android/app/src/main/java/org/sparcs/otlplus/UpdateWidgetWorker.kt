package org.sparcs.otlplus

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import org.sparcs.otlplus.api.ApiLoader
import org.sparcs.otlplus.api.TimetableData

class UpdateWidgetWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    private val CHANNEL = "https://otl.kaist.ac.kr"

    override fun doWork(): Result {
        val apiLoader = ApiLoader(applicationContext)
        val appWidgetManager = AppWidgetManager.getInstance(applicationContext)

        // 1. Get current semester
        val semesterDataString = apiLoader.getSync("$CHANNEL/api/v2/semesters/current") ?: return Result.retry()
        val semesterJsonObject = JSONObject(semesterDataString)
        val year = semesterJsonObject.getInt("year")
        val semester = semesterJsonObject.getInt("semester")

        // 2. Get timetable data
        val timetableDataString = apiLoader.getSync("$CHANNEL/api/v2/timetables/my-timetable?year=$year&semester=$semester") ?: return Result.retry()
        val timetableData = TimetableData(timetableDataString)

        // 3. Update NextLectureWidget
        val nextLectureComponentName = ComponentName(applicationContext, NextLectureWidget::class.java)
        val nextLectureIds = appWidgetManager.getAppWidgetIds(nextLectureComponentName)
        for (appWidgetId in nextLectureIds) {
            updateNextLectureWidget(applicationContext, appWidgetManager, appWidgetId, timetableData)
        }

        // 4. Update TimetableWidget
        val timetableComponentName = ComponentName(applicationContext, TimetableWidget::class.java)
        val timetableIds = appWidgetManager.getAppWidgetIds(timetableComponentName)
        for (appWidgetId in timetableIds) {
            updateTimetableWidget(applicationContext, appWidgetManager, appWidgetId, timetableData)
        }

        return Result.success()
    }
}
