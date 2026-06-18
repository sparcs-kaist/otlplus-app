package org.sparcs.otlplus.api

import org.json.JSONArray
import org.json.JSONObject

class TimetableData(jsonString: String) {
    var lectures: List<Lecture> = listOf()

    init {
        try {
            val jsonObject = JSONObject(jsonString)
            val myTimetableLectures = jsonObject.getJSONArray("lectures")

            lectures = (0 until myTimetableLectures.length()).mapNotNull { index ->
                val lectureJsonObject = myTimetableLectures.getJSONObject(index)
                Lecture(
                        name = lectureJsonObject.getString("name") + lectureJsonObject.getString("subtitle"),
                        timeBlocks = toTimeBlocks(
                            lectureJsonObject.getJSONArray("classes")
                        ),
                        place = lectureJsonObject.getJSONArray("classes")
                            .getJSONObject(0).let { classJsonObject ->
                                "(" + classJsonObject.getString("buildingCode") + ") " + classJsonObject.getString("roomName")
                                                  },
                        professor = lectureJsonObject.getJSONArray("professors")
                            .getJSONObject(0)
                            .getString("name"),
                        course = lectureJsonObject.getInt("courseId")
                    )
            }
        } catch (e: Exception) {
//            e.printStackTrace()
        }
    }

    private fun toTimeBlocks(classTimes: JSONArray): List<TimeBlock> =
        (0 until classTimes.length()).map { index ->
            val date = classTimes.getJSONObject(index).getInt("day")
            val begin = classTimes.getJSONObject(index).getInt("begin")
            val end = classTimes.getJSONObject(index).getInt("end")

            TimeBlock(
                weekday = when (date) {
                    0 -> WeekDays.Mon
                    1 -> WeekDays.Tue
                    2 -> WeekDays.Wed
                    3 -> WeekDays.Thu
                    4 -> WeekDays.Fri
                    else -> WeekDays.Undef
                },
                start = LocalTime(
                    hours = begin / 60,
                    minutes = begin % 60
                ),
                end = LocalTime(
                    hours = end / 60,
                    minutes = end % 60
                )
            )
        }
}