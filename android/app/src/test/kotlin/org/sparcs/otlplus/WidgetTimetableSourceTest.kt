package org.sparcs.otlplus

import android.content.SharedPreferences
import java.lang.reflect.Proxy
import org.junit.Assert.*
import org.junit.Test
import org.sparcs.otlplus.api.ApiLoadFailure
import org.sparcs.otlplus.api.ApiLoadResult

class WidgetTimetableSourceTest {
    @Test
    fun `my timetable uses current semester while saved timetable uses stable id`() {
        val urls = mutableListOf<String>()
        val source = WidgetTimetableSource({ url -> urls += url; ApiLoadResult(body = "{\"lectures\":[]}") })
        source.timetable(0, WidgetSemester(2026, 3))
        source.timetable(72, null)
        assertEquals(listOf(
            "https://otl.kaist.ac.kr/api/v2/timetables/my-timetable?year=2026&semester=3",
            "https://otl.kaist.ac.kr/api/v2/timetables/72",
        ), urls)
    }

    @Test
    fun `options preserve server ids names and order including unnamed tables`() {
        val source = WidgetTimetableSource({ url ->
            assertEquals("https://otl.kaist.ac.kr/api/v2/timetables?year=2026&semester=3", url)
            ApiLoadResult(body = """{"timetables":[{"id":72,"name":"Study"},{"id":13,"name":""}]}""")
        })
        assertEquals(listOf(WidgetTimetableOption(72, "Study"), WidgetTimetableOption(13, "")),
            source.options(WidgetSemester(2026, 3)).first)
    }

    @Test
    fun `list failure stays a failure rather than an empty selection list`() {
        val source = WidgetTimetableSource({ ApiLoadResult(failure = ApiLoadFailure.REJECTED) })
        val result = source.options(WidgetSemester(2026, 3))
        assertNull(result.first)
        assertEquals(ApiLoadFailure.REJECTED, result.second.failure)
    }

    @Test
    fun `different widget selections resolve independently`() {
        val source = WidgetTimetableSource({ url ->
            if (url.endsWith("/13")) ApiLoadResult(failure = ApiLoadFailure.UNAVAILABLE)
            else ApiLoadResult(body = "{\"lectures\":[]}")
        })
        assertNull(source.timetable(13, null).body)
        assertNotNull(source.timetable(72, null).body)
    }
    @Test
    fun `unavailable current semester does not block saved timetable widgets`() {
        val urls = mutableListOf<String>()
        val source = WidgetTimetableSource({ url ->
            urls += url
            if (url.endsWith("/current")) ApiLoadResult(failure = ApiLoadFailure.UNAVAILABLE)
            else ApiLoadResult(body = "{\"lectures\":[]}")
        })
        val loaded = source.loadSelections(listOf(0, 72, 72))
        assertNull(loaded.getValue(0).body)
        assertNotNull(loaded.getValue(72).body)
        assertEquals(2, urls.size)
    }

    @Test
    fun `widget preferences stay independent and survive recreation`() {
        val backing = memoryPreferences()
        val preferences = WidgetTimetablePreferences(backing)
        assertEquals(0, preferences.selectedId(1))
        preferences.save(1, 72)
        preferences.save(2, 13)
        val reopened = WidgetTimetablePreferences(backing)
        assertEquals(72, reopened.selectedId(1))
        assertEquals(13, reopened.selectedId(2))
        reopened.delete(intArrayOf(1))
        assertEquals(0, reopened.selectedId(1))
        assertEquals(13, reopened.selectedId(2))
    }

    @Test
    fun `restored widget ids retain selections even when old and new ids overlap`() {
        val preferences = WidgetTimetablePreferences(memoryPreferences())
        preferences.save(1, 72)
        preferences.save(2, 13)
        preferences.restore(intArrayOf(1, 2), intArrayOf(2, 3))
        assertEquals(0, preferences.selectedId(1))
        assertEquals(72, preferences.selectedId(2))
        assertEquals(13, preferences.selectedId(3))
    }

    private fun memoryPreferences(): SharedPreferences {
        val values = mutableMapOf<String, Int>()
        return Proxy.newProxyInstance(SharedPreferences::class.java.classLoader, arrayOf(SharedPreferences::class.java)) { _, method, args ->
            when (method.name) {
                "getInt" -> values[args!![0] as String] ?: args[1]
                "edit" -> {
                    val changes = mutableMapOf<String, Int?>()
                    Proxy.newProxyInstance(SharedPreferences.Editor::class.java.classLoader, arrayOf(SharedPreferences.Editor::class.java)) { editor, operation, arguments ->
                        when (operation.name) {
                            "putInt" -> { changes[arguments!![0] as String] = arguments[1] as Int; editor }
                            "remove" -> { changes[arguments!![0] as String] = null; editor }
                            "commit", "apply" -> {
                                changes.forEach { (key, value) -> if (value == null) values.remove(key) else values[key] = value }
                                true
                            }
                            else -> null
                        }
                    }
                }
                else -> null
            }
        } as SharedPreferences
    }

}
