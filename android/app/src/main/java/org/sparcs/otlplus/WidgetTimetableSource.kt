package org.sparcs.otlplus

import org.json.JSONObject
import org.json.JSONException
import org.sparcs.otlplus.api.ApiLoadFailure
import org.sparcs.otlplus.api.ApiLoadResult

internal data class WidgetTimetableOption(val id: Int, val name: String)
internal data class WidgetSemester(val year: Int, val semester: Int)

/** Zero identifies the read-only current-semester timetable, as on iOS. */
internal class WidgetTimetableSource(
    private val get: (String) -> ApiLoadResult,
    private val baseUrl: String = "https://otl.kaist.ac.kr",
) {
    fun currentSemester(): Pair<WidgetSemester?, ApiLoadResult> {
        val result = get("$baseUrl/api/v2/semesters/current")
        val body = result.body ?: return null to result
        val json = JSONObject(body)
        return WidgetSemester(json.getInt("year"), json.getInt("semester")) to result
    }

    fun options(semester: WidgetSemester): Pair<List<WidgetTimetableOption>?, ApiLoadResult> {
        val result = get("$baseUrl/api/v2/timetables?year=${semester.year}&semester=${semester.semester}")
        val body = result.body ?: return null to result
        val tables = JSONObject(body).getJSONArray("timetables")
        return (0 until tables.length()).map { index ->
            val table = tables.getJSONObject(index)
            WidgetTimetableOption(table.getInt("id"), table.getString("name"))
        } to result
    }

    fun loadSelections(ids: Collection<Int>): Map<Int, ApiLoadResult> {
        val current = if (0 in ids) try {
            currentSemester()
        } catch (_: JSONException) {
            null to ApiLoadResult(failure = ApiLoadFailure.UNAVAILABLE)
        } else null
        return ids.distinct().associateWith { id ->
            if (id == 0 && current?.first == null) current?.second ?: ApiLoadResult(failure = ApiLoadFailure.UNAVAILABLE)
            else timetable(id, current?.first)
        }
    }

    fun timetable(id: Int, semester: WidgetSemester?): ApiLoadResult {
        require(id >= 0)
        val url = if (id == 0) {
            requireNotNull(semester)
            "$baseUrl/api/v2/timetables/my-timetable?year=${semester.year}&semester=${semester.semester}"
        } else {
            "$baseUrl/api/v2/timetables/$id"
        }
        val result = get(url)
        if (id == 0 || result.body == null) return result
        val detail = JSONObject(result.body)
        if (detail.has("timetableItems")) return result
        val customResult = get("$url/custom-blocks")
        val body = customResult.body ?: return customResult
        val blocks = JSONObject(body).getJSONArray("custom_blocks")
        val items = org.json.JSONArray()
        for (index in 0 until blocks.length()) {
            items.put(JSONObject().put("kind", "custom").put("data", blocks.getJSONObject(index)))
        }
        detail.put("timetableItems", items)
        return ApiLoadResult(body = detail.toString())
    }
}
