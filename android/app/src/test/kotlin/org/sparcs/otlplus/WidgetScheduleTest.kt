package org.sparcs.otlplus

import java.util.Calendar
import java.util.TimeZone
import org.junit.Assert.*
import org.junit.Test
import org.sparcs.otlplus.api.NextLectureData
import org.sparcs.otlplus.api.TimetableData

class WidgetScheduleTest {
    private val custom = """{"kind":"custom","data":{"id":12,"block_name":"Study","place":"Library","day":0,"begin":60,"end":120,"times":[{"day":0,"begin":60,"end":120},{"day":6,"begin":1380,"end":1440}]}}"""
    private fun table(lectures: String = "[]") = TimetableData("""{"lectures":$lectures,"timetableItems":[$custom]}""")
    private fun date(day: Int, hour: Int, minute: Int) = Calendar.getInstance(TimeZone.getTimeZone("Asia/Seoul")).apply {
        set(2026, Calendar.SEPTEMBER, day, hour, minute, 0)
    }

    @Test
    fun `custom occurrences preserve every time place and app palette`() {
        val items = table().schedule
        assertEquals(2, items.size)
        assertEquals(listOf(0, 6), items.map { it.day })
        assertEquals(1440, items.last().end)
        assertEquals("Library", items.last().place)
        assertTrue(items.all { it.isCustom && it.professor.isEmpty() && it.colorIndex == 11 })
    }

    @Test
    fun `weekly grid keeps a bounded shared window and preserves weekends`() {
        val morning = widgetGridRange(table().schedule, date(28, 0, 0))
        assertEquals(7, morning.days)
        assertEquals(1, morning.startHour)
        assertEquals(9, morning.endHour)
        val daytime = widgetGridRange(table().schedule, date(28, 10, 0))
        assertEquals(9, daytime.startHour)
        assertEquals(17, daytime.endHour)
        val evening = widgetGridRange(table().schedule, date(28, 23, 0))
        assertEquals(16, evening.startHour)
        assertEquals(24, evening.endHour)
        val larger = widgetGridRange(table().schedule, date(28, 10, 0), visibleHours = 10)
        assertEquals(10, larger.endHour - larger.startHour)
    }

    @Test
    fun `next occurrence wraps Sunday to Monday and does not invent a professor`() {
        val next = NextLectureData.getNextLecture(table(), date(27, 23, 30))!!
        assertEquals("Study", next.name)
        assertEquals("내일 01:00", next.date)
        assertEquals("", next.professor)
    }

    @Test
    fun `event at current minute is included and past sole event wraps to next week`() {
        assertEquals("오늘 23:00", NextLectureData.getNextLecture(table(), date(27, 23, 0))!!.date)
        val mondayOnly = TimetableData("""{"lectures":[],"timetableItems":[{"kind":"custom","data":{"id":1,"block_name":"Weekly","place":"","times":[{"day":0,"begin":60,"end":120}]}}]}""")
        assertEquals("Weekly", NextLectureData.getNextLecture(mondayOnly, date(28, 2, 0))!!.name)
    }

    @Test
    fun `unscheduled lecture does not hide custom blocks and empty schedule is safe`() {
        val lectures = """[{"name":"No class","subtitle":"","courseId":9,"professors":[],"classes":[]}]"""
        assertEquals(2, table(lectures).schedule.size)
        assertNull(NextLectureData.getNextLecture(TimetableData("""{"lectures":[],"timetableItems":[]}""")))
    }
}
