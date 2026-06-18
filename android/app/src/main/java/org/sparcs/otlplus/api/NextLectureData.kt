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
    fun getNextLecture(timetableData: TimetableData): NextLectureInfo? {
        val calendar = Calendar.getInstance()
        val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
        val hours = calendar.get(Calendar.HOUR_OF_DAY)
        val minutes = calendar.get(Calendar.MINUTE)
        val totalMinutes = hours * 60 + minutes

        // Calendar.MONDAY is 2, ..., Calendar.FRIDAY is 6
        // Map to 0 (Mon) ... 4 (Fri)
        val todayIndex = when (dayOfWeek) {
            Calendar.MONDAY -> 0
            Calendar.TUESDAY -> 1
            Calendar.WEDNESDAY -> 2
            Calendar.THURSDAY -> 3
            Calendar.FRIDAY -> 4
            Calendar.SATURDAY -> 5
            Calendar.SUNDAY -> 6
            else -> -1
        }

        val weekDays = WeekDays.entries.toTypedArray()

        // Find next lecture today or in the future
        for (i in 0 until 7) {
            val checkDayIndex = (todayIndex + i) % 7
            if (checkDayIndex >= 5) continue // Skip Sat, Sun for now as OTL usually doesn't have them

            val checkDay = weekDays[checkDayIndex]
            
            val upcomingLectures = timetableData.lectures.flatMap { lecture ->
                lecture.timeBlocks
                    .filter { it.weekday == checkDay }
                    .map { it to lecture }
            }.filter { (timeBlock, _) ->
                if (i == 0) {
                    // If today, must be after current time
                    (timeBlock.start.hours * 60 + timeBlock.start.minutes) > totalMinutes
                } else {
                    true
                }
            }.sortedBy { it.first.start.hours * 60 + it.first.start.minutes }

            if (upcomingLectures.isNotEmpty()) {
                val (nextTimeBlock, nextLecture) = upcomingLectures.first()
                val dateString = formatDateString(i, nextTimeBlock)
                return NextLectureInfo(
                    date = dateString,
                    name = nextLecture.name,
                    place = nextLecture.place,
                    professor = nextLecture.professor + " 교수님",
                    course = nextLecture.course,
                )
            }
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
                    else -> ""
                }
                "$dayName $startTime"
            }
        }
    }
}
