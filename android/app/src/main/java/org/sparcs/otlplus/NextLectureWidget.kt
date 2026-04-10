package org.sparcs.otlplus

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import androidx.work.*
import org.sparcs.otlplus.api.NextLectureData
import org.sparcs.otlplus.api.TimetableData
import org.sparcs.otlplus.constants.BlockColor
import java.util.concurrent.TimeUnit

/**
 * Implementation of App Widget functionality.
 */

class NextLectureWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Schedule periodic update if not already scheduled
        schedulePeriodicUpdate(context)

        // Trigger immediate update via WorkManager
        val workRequest = OneTimeWorkRequestBuilder<UpdateWidgetWorker>()
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        WorkManager.getInstance(context).enqueue(workRequest)
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

    override fun onDisabled(context: Context) {

        // WorkManager will be cancelled if all widgets are removed and you want to stop background updates
        // However, TimetableWidget also uses the same worker, so we might want to keep it
        // unless both are disabled. For now, keeping it simple.
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
            it.setViewVisibility(R.id.nextLectureColor, View.VISIBLE)
            it.setInt(R.id.nextLectureColor, "setColorFilter", BlockColor.getColor(nextLectureInfo.course))
        } else {
            it.setTextViewText(R.id.nextLectureDate, "")
            it.setTextViewText(R.id.nextLectureName, "다음 강의가 없습니다.")
            it.setTextViewText(R.id.nextLecturePlace, "")
            it.setTextViewText(R.id.nextLectureProfessor, "")
            it.setViewVisibility(R.id.nextLectureColor, View.GONE)
        }
        // Instruct the widget manager to update the widget
        appWidgetManager.updateAppWidget(appWidgetId, it)
    }
}
