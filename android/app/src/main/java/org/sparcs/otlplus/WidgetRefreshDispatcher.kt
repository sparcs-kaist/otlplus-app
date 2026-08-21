package org.sparcs.otlplus

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Constraints
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager

object WidgetRefreshDispatcher {
    private const val IMMEDIATE_WORK_NAME = "WidgetImmediateUpdateWork"

    fun refresh(context: Context) {
        val applicationContext = context.applicationContext
        val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
        val hasTimetableWidgets = appWidgetManager.getAppWidgetIds(
            ComponentName(applicationContext, TimetableWidget::class.java),
        ).isNotEmpty()
        val hasNextLectureWidgets = appWidgetManager.getAppWidgetIds(
            ComponentName(applicationContext, NextLectureWidget::class.java),
        ).isNotEmpty()
        if (!hasTimetableWidgets && !hasNextLectureWidgets) return

        val workRequest = OneTimeWorkRequestBuilder<UpdateWidgetWorker>()
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build(),
            )
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()
        WorkManager.getInstance(applicationContext).enqueueUniqueWork(
            IMMEDIATE_WORK_NAME,
            ExistingWorkPolicy.KEEP,
            workRequest,
        )
    }
}
