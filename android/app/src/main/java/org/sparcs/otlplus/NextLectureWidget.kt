package org.sparcs.otlplus

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import org.sparcs.otlplus.api.ApiLoader
import org.sparcs.otlplus.api.NextLectureData
import org.sparcs.otlplus.api.TimetableData
import org.json.JSONObject

/**
 * Implementation of App Widget functionality.
 */

class NextLectureWidget : AppWidgetProvider() {
    private val CHANNEL = "https://otl.sparcs.org"

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val apiLoader = ApiLoader(context)

        apiLoader.get("$CHANNEL/api/v2/semesters/current") { semesterDataString ->
            val semesterJsonObject = JSONObject(semesterDataString)
            apiLoader.get("$CHANNEL/api/v2/timetables/my-timetable?year=${semesterJsonObject.getInt("year")}&semester=${semesterJsonObject.getInt("semester")}") { dataString ->
                val timetableData = TimetableData(dataString)

                for (appWidgetId in appWidgetIds) {
                    updateNextLectureWidget(context, appWidgetManager, appWidgetId, timetableData)
                }
            }
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
}

internal fun updateNextLectureWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    timetableData: TimetableData,
) {
    val nextLectureInfo = NextLectureData.getNextLecture(timetableData)

    // Construct the RemoteViews object
    RemoteViews(context.packageName, R.layout.next_lecture_widget).let {
        if (nextLectureInfo != null) {
            it.setTextViewText(R.id.nextLectureDate, nextLectureInfo.date)
            it.setTextViewText(R.id.nextLectureName, nextLectureInfo.name)
            it.setTextViewText(R.id.nextLecturePlace, nextLectureInfo.place)
            it.setTextViewText(R.id.nextLectureProfessor, nextLectureInfo.professor)
        } else {
            it.setTextViewText(R.id.nextLectureDate, "")
            it.setTextViewText(R.id.nextLectureName, "다음 강의가 없습니다.")
            it.setTextViewText(R.id.nextLecturePlace, "")
            it.setTextViewText(R.id.nextLectureProfessor, "")
        }
        // Instruct the widget manager to update the widget
        appWidgetManager.updateAppWidget(appWidgetId, it)
    }
}
