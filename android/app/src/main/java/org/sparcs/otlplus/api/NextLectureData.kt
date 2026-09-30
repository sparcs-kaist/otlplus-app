package org.sparcs.otlplus.api

import java.util.Calendar

data class NextLectureInfo(
    val date: String,
    val name: String,
    val place: String,
    val professor: String,
    val course: Int,
)

object NextLectureData {
    fun getNextLecture(timetableData: TimetableData, calendar: Calendar = Calendar.getInstance(java.util.TimeZone.getTimeZone("Asia/Seoul"))): NextLectureInfo? {
        val today = (calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7
        val minutes = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        // Include next week's occurrence when today's only event has passed.
        for (offset in 0..7) {
            val day = (today + offset) % 7
            val next = timetableData.schedule.filter { it.day == day && (offset != 0 || it.begin >= minutes) }.minByOrNull { it.begin } ?: continue
            val time = TimeBlock(WeekDays.entries[day], LocalTime(next.begin / 60, next.begin % 60), LocalTime(next.end / 60, next.end % 60))
            return NextLectureInfo(formatDateString(offset, time), next.name, next.place,
                if (next.professor.isEmpty()) "" else next.professor + " 교수님", next.colorIndex)
        }
        return null
    }

    private fun formatDateString(daysOffset: Int, timeBlock: TimeBlock): String {
        val startTime = String.format("%02d:%02d", timeBlock.start.hours, timeBlock.start.minutes)
        return when (daysOffset) {
            0 -> "오늘 $startTime"
            1 -> "내일 $startTime"
            else -> {
                val dayName = when (timeBlock.weekday) {
                    WeekDays.Mon -> "월요일"
                    WeekDays.Tue -> "화요일"
                    WeekDays.Wed -> "수요일"
                    WeekDays.Thu -> "목요일"
                    WeekDays.Fri -> "금요일"
                    WeekDays.Sat -> "토요일"
                    WeekDays.Sun -> "일요일"
                    else -> ""
                }
                "$dayName $startTime"
            }
        }
    }
}
