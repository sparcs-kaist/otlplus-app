package org.sparcs.otlplus.api

enum class WeekDays {
    Mon,
    Tue,
    Wed,
    Thu,
    Fri,
    Sat,
    Sun,
    Undef,
}

data class LocalTime(
    val hours: Int,
    val minutes: Int,
) {
    val hoursFloat: Float
        get() = hours + minutes / 60f
}

data class TimeBlock(
    val weekday: WeekDays,
    val start: LocalTime,
    val end: LocalTime
)

data class Lecture(
    val name: String,
    val timeBlocks: List<TimeBlock>,
    val place: String,
    val professor: String,
    val course: Int,
)