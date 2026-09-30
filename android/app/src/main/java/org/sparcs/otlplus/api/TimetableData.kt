package org.sparcs.otlplus.api

import org.json.JSONArray
import org.json.JSONObject

/** A renderable occurrence, shared by grid and next-event widgets. */
data class WidgetScheduleItem(
    val name: String,
    val place: String,
    val professor: String,
    val day: Int,
    val begin: Int,
    val end: Int,
    val colorIndex: Int,
    val isCustom: Boolean = false,
)

class TimetableData(jsonString: String) {
    val schedule: List<WidgetScheduleItem>
    // Kept for callers that need lecture-only data.
    val lectures: List<Lecture>

    init {
        val json = JSONObject(jsonString)
        val parsed = mutableListOf<WidgetScheduleItem>()
        val lectureList = json.getJSONArray("lectures")
        lectures = (0 until lectureList.length()).map { index ->
            val lecture = lectureList.getJSONObject(index)
            val classes = lecture.getJSONArray("classes")
            val name = lecture.getString("name") + lecture.optString("subtitle")
            val professors = lecture.optJSONArray("professors")
            val professor = if (professors != null && professors.length() > 0) professors.getJSONObject(0).getString("name") else ""
            val course = lecture.getInt("courseId")
            val blocks = (0 until classes.length()).map { classIndex ->
                val time = classes.getJSONObject(classIndex)
                val day = time.getInt("day")
                val begin = time.getInt("begin")
                val end = time.getInt("end")
                val place = listOf(time.optString("buildingCode").takeIf { it.isNotEmpty() }?.let { "($it)" }, time.optString("roomName").takeIf { it.isNotEmpty() }).filterNotNull().joinToString(" ")
                if (validTime(day, begin, end)) parsed += WidgetScheduleItem(name, place, professor, day, begin, end, Math.floorMod(course, 16))
                TimeBlock(WeekDays.entries.getOrElse(day) { WeekDays.Undef }, LocalTime(begin / 60, begin % 60), LocalTime(end / 60, end % 60))
            }
            Lecture(name, blocks, parsed.lastOrNull { !it.isCustom && it.name == name }?.place ?: "", professor, course)
        }
        val items = json.optJSONArray("timetableItems") ?: JSONArray()
        for (index in 0 until items.length()) {
            val item = items.getJSONObject(index)
            if (item.optString("kind") != "custom") continue
            val block = item.getJSONObject("data")
            val times = block.getJSONArray("times")
            for (timeIndex in 0 until times.length()) {
                val time = times.getJSONObject(timeIndex)
                val day = time.getInt("day")
                val begin = time.getInt("begin")
                val end = time.getInt("end")
                if (validTime(day, begin, end)) parsed += WidgetScheduleItem(
                    block.getString("block_name"), block.getString("place"), "", day, begin, end,
                    ((block.getLong("id") % 16 * 3 + 7) % 16).toInt(), true,
                )
            }
        }
        schedule = parsed.toList()
    }

    private fun validTime(day: Int, begin: Int, end: Int) = day in 0..6 && begin >= 0 && begin < end && end <= 1440
}
