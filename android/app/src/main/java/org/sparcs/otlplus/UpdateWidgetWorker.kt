package org.sparcs.otlplus

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONException
import org.json.JSONObject
import org.sparcs.otlplus.api.ApiLoadFailure
import org.sparcs.otlplus.api.ApiLoadResult
import org.sparcs.otlplus.api.ApiLoader
import org.sparcs.otlplus.api.TimetableData

class UpdateWidgetWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    private val channel = "https://otl.kaist.ac.kr"

    override fun doWork(): Result {
        val apiLoader = ApiLoader(applicationContext)
        val appWidgetManager = AppWidgetManager.getInstance(applicationContext)

        return try {
            val semesterResult = apiLoader.getSyncResult("$channel/api/v2/semesters/current")
            val semesterDataString = semesterResult.body ?: return resultFor(semesterResult)
            val semesterJsonObject = JSONObject(semesterDataString)
            val year = semesterJsonObject.getInt("year")
            val semester = semesterJsonObject.getInt("semester")

            val timetableResult = apiLoader.getSyncResult(
                "$channel/api/v2/timetables/my-timetable?year=$year&semester=$semester",
            )
            val timetableDataString = timetableResult.body ?: return resultFor(timetableResult)
            val timetableData = TimetableData(timetableDataString)

            val nextLectureComponentName = ComponentName(
                applicationContext,
                NextLectureWidget::class.java,
            )
            val nextLectureIds = appWidgetManager.getAppWidgetIds(nextLectureComponentName)
            for (appWidgetId in nextLectureIds) {
                updateNextLectureWidget(
                    applicationContext,
                    appWidgetManager,
                    appWidgetId,
                    timetableData,
                )
            }

            val timetableComponentName = ComponentName(
                applicationContext,
                TimetableWidget::class.java,
            )
            val timetableIds = appWidgetManager.getAppWidgetIds(timetableComponentName)
            for (appWidgetId in timetableIds) {
                updateTimetableWidget(
                    applicationContext,
                    appWidgetManager,
                    appWidgetId,
                    timetableData,
                )
            }

            Result.success()
        } catch (_: JSONException) {
            Result.retry()
        }
    }

    private fun resultFor(result: ApiLoadResult): Result {
        return if (result.failure == ApiLoadFailure.REJECTED) {
            Result.failure()
        } else {
            Result.retry()
        }
    }
}
