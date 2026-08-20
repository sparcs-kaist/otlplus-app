import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/timetable.dart";

class TimetableCollection {
  TimetableCollection({
    required List<TimetableListItem> summaries,
    required List<Timetable> timetables,
  }) : summaries = List<TimetableListItem>.unmodifiable(summaries),
       timetables = List<Timetable>.unmodifiable(timetables);

  final List<TimetableListItem> summaries;
  final List<Timetable> timetables;
}

enum TimetableLectureAction { add, delete }

class TimetableRepository {
  TimetableRepository(this._dio);

  final Dio _dio;

  Future<TimetableCollection> fetchBySemester(int year, int semester) async {
    _validateYear(year);
    _validateSemester(semester);

    final response = await _dio.get<Map<String, dynamic>>(
      API_V2_TIMETABLES_URL,
      queryParameters: <String, dynamic>{"year": year, "semester": semester},
    );
    final data = response.data as Map<String, dynamic>;
    final summaries = List<TimetableListItem>.unmodifiable(
      (data["timetables"] as List<dynamic>).map(
        (summary) =>
            TimetableListItem.fromV2Json(summary as Map<String, dynamic>),
      ),
    );
    final timetables = await Future.wait(summaries.map(_fetchDetail));

    return TimetableCollection(summaries: summaries, timetables: timetables);
  }

  Future<Timetable> fetchMyTimetable(int year, int semester) async {
    _validateYear(year);
    _validateSemester(semester);

    final response = await _dio.get<Map<String, dynamic>>(
      API_V2_MY_TIMETABLE_URL,
      queryParameters: <String, dynamic>{"year": year, "semester": semester},
    );
    return Timetable.fromV2MyTimetable(
      response.data as Map<String, dynamic>,
      year: year,
      semester: semester,
    );
  }

  Future<int> create({
    required int year,
    required int semester,
    required List<int> lectureIds,
  }) async {
    _validateYear(year);
    _validateSemester(semester);
    _validateIds(lectureIds, "lectureIds");

    final response = await _dio.post<Map<String, dynamic>>(
      API_V2_TIMETABLES_URL,
      data: <String, dynamic>{
        "year": year,
        "semester": semester,
        "lectureIds": List<int>.of(lectureIds),
      },
    );
    final data = response.data as Map<String, dynamic>;
    final id = data["id"] as int;
    if (id <= 0) throw const FormatException("id must be positive");
    return id;
  }

  Future<Timetable> updateLecture({
    required TimetableListItem summary,
    required int lectureId,
    required TimetableLectureAction action,
  }) async {
    _validatePositiveId(lectureId, "lectureId");
    final path = API_V2_TIMETABLE_DETAIL_URL.replaceFirst(
      "{id}",
      summary.id.toString(),
    );
    await _dio.patch<Map<String, dynamic>>(
      path,
      data: <String, dynamic>{"lectureId": lectureId, "action": action.name},
    );
    return _fetchDetail(summary);
  }

  Future<void> delete(int id) async {
    _validatePositiveId(id, "id");
    await _dio.delete<Map<String, dynamic>>(
      API_V2_TIMETABLES_URL,
      data: <String, dynamic>{"id": id},
    );
  }

  Future<Timetable> _fetchDetail(TimetableListItem summary) async {
    final response = await _dio.get<Map<String, dynamic>>(
      API_V2_TIMETABLE_DETAIL_URL.replaceFirst("{id}", summary.id.toString()),
    );
    return Timetable.fromV2Detail(
      response.data as Map<String, dynamic>,
      summary: summary,
    );
  }
}

void _validateYear(int year) {
  if (year <= 0) {
    throw ArgumentError.value(year, "year", "must be positive");
  }
}

void _validateSemester(int semester) {
  if (semester < 1 || semester > 4) {
    throw ArgumentError.value(semester, "semester", "must be between 1 and 4");
  }
}

void _validateIds(List<int> ids, String name) {
  for (var index = 0; index < ids.length; index++) {
    _validatePositiveId(ids[index], "$name[$index]");
  }
}

void _validatePositiveId(int id, String name) {
  if (id <= 0) {
    throw ArgumentError.value(id, name, "must be positive");
  }
}
