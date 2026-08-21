import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/models/timetable.dart";
import "package:otlplus/repositories/timetable_repository.dart";

import "../utils/fake_http.dart";

class CapturingHttpAdapter extends FakeHttpAdapter {
  CapturingHttpAdapter({this.detailDelay = Duration.zero});

  final Duration detailDelay;
  final List<RequestOptions> requests = <RequestOptions>[];
  int activeDetailRequests = 0;
  int maxActiveDetailRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final isDetailRequest =
        options.method == "GET" &&
        options.uri.path.startsWith("/$API_V2_TIMETABLES_URL/");
    if (!isDetailRequest || detailDelay == Duration.zero) {
      return super.fetch(options, requestStream, cancelFuture);
    }

    activeDetailRequests++;
    if (activeDetailRequests > maxActiveDetailRequests) {
      maxActiveDetailRequests = activeDetailRequests;
    }
    try {
      await Future<void>.delayed(detailDelay);
      return await super.fetch(options, requestStream, cancelFuture);
    } finally {
      activeDetailRequests--;
    }
  }
}

void main() {
  late CapturingHttpAdapter adapter;
  late TimetableRepository repository;
  late Map<String, dynamic> listFixture;
  late Map<String, dynamic> detailFixture;

  setUp(() async {
    listFixture =
        jsonDecode(
              await File(
                "test/fixtures/v2/timetables_list.json",
              ).readAsString(),
            )
            as Map<String, dynamic>;
    detailFixture =
        jsonDecode(
              await File(
                "test/fixtures/v2/timetable_detail.json",
              ).readAsString(),
            )
            as Map<String, dynamic>;
    adapter = CapturingHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: "http://test/"))
      ..httpClientAdapter = adapter;
    repository = TimetableRepository(dio);
  });

  group("TimetableRepository.fetchBySemester", () {
    test("fetches details concurrently and preserves summary order", () async {
      adapter = CapturingHttpAdapter(
        detailDelay: const Duration(milliseconds: 20),
      );
      final dio = Dio(BaseOptions(baseUrl: "http://test/"))
        ..httpClientAdapter = adapter;
      repository = TimetableRepository(dio);
      final firstSummary = Map<String, dynamic>.from(
        (listFixture["timetables"] as List<dynamic>).single
            as Map<String, dynamic>,
      )..addAll(<String, dynamic>{"id": 7, "name": "첫 시간표"});
      final secondSummary = <String, dynamic>{
        ...firstSummary,
        "id": 3,
        "name": "둘째 시간표",
        "timeTableOrder": 1,
      };
      final listResponse = <String, dynamic>{
        "timetables": <Map<String, dynamic>>[firstSummary, secondSummary],
      };
      adapter.register(
        "GET",
        "/$API_V2_TIMETABLES_URL?semester=3&year=2026",
        listResponse,
      );
      for (final id in <int>[7, 3]) {
        adapter.register(
          "GET",
          "/${API_V2_TIMETABLE_DETAIL_URL.replaceFirst("{id}", id.toString())}",
          detailFixture,
        );
      }

      final collection = await repository.fetchBySemester(2026, 3);

      expect(collection.summaries.map((summary) => summary.id), <int>[7, 3]);
      expect(
        collection.summaries.map((summary) => summary.timeTableOrder),
        <int>[0, 1],
      );
      expect(collection.timetables.map((timetable) => timetable.id), <int>[
        7,
        3,
      ]);
      expect(collection.timetables.first.lectures.single.year, 2026);
      expect(collection.timetables.first.lectures.single.semester, 3);
      expect(adapter.requests, hasLength(3));
      expect(
        adapter.requests.map((request) => request.method).toList(),
        <String>["GET", "GET", "GET"],
      );
      expect(
        adapter.requests.map((request) => request.uri.path).toList(),
        <String>[
          "/$API_V2_TIMETABLES_URL",
          "/${API_V2_TIMETABLE_DETAIL_URL.replaceFirst("{id}", "7")}",
          "/${API_V2_TIMETABLE_DETAIL_URL.replaceFirst("{id}", "3")}",
        ],
      );
      expect(adapter.requests.first.queryParameters, <String, dynamic>{
        "year": 2026,
        "semester": 3,
      });
      expect(adapter.requests[1].queryParameters, isEmpty);
      expect(adapter.requests[2].queryParameters, isEmpty);
      expect(adapter.maxActiveDetailRequests, 2);
    });

    test("does not request details when the summary list is empty", () async {
      adapter.register(
        "GET",
        "/$API_V2_TIMETABLES_URL?semester=3&year=2026",
        <String, dynamic>{"timetables": <dynamic>[]},
      );

      final collection = await repository.fetchBySemester(2026, 3);

      expect(collection.summaries, isEmpty);
      expect(collection.timetables, isEmpty);
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.uri.path, "/$API_V2_TIMETABLES_URL");
    });

    test(
      "strictly rejects an invalid summary before requesting details",
      () async {
        adapter.register(
          "GET",
          "/$API_V2_TIMETABLES_URL?semester=3&year=2026",
          <String, dynamic>{
            "timetables": <Map<String, dynamic>>[
              <String, dynamic>{
                ...(listFixture["timetables"] as List<dynamic>).single
                    as Map<String, dynamic>,
                "id": "1",
              },
            ],
          },
        );

        await expectLater(
          repository.fetchBySemester(2026, 3),
          throwsA(isA<TypeError>()),
        );
        expect(adapter.requests, hasLength(1));
        expect(adapter.requests.single.uri.path, "/$API_V2_TIMETABLES_URL");
      },
    );

    test("validates year and semester before HTTP", () async {
      await expectLater(repository.fetchBySemester(0, 3), throwsArgumentError);
      await expectLater(
        repository.fetchBySemester(2026, 0),
        throwsArgumentError,
      );
      await expectLater(
        repository.fetchBySemester(2026, 5),
        throwsArgumentError,
      );

      expect(adapter.requests, isEmpty);
    });
  });

  group("TimetableRepository.fetchMyTimetable", () {
    test("uses the dedicated endpoint and supplied semester context", () async {
      adapter.register(
        "GET",
        "/$API_V2_MY_TIMETABLE_URL?semester=3&year=2026",
        detailFixture,
      );

      final timetable = await repository.fetchMyTimetable(2026, 3);

      expect(timetable.id, anyOf(0, -1));
      expect(timetable.lectures.single.id, 1921750);
      expect(timetable.lectures.single.year, 2026);
      expect(timetable.lectures.single.semester, 3);
      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, "GET");
      expect(request.uri.path, "/$API_V2_MY_TIMETABLE_URL");
      expect(request.queryParameters, <String, dynamic>{
        "year": 2026,
        "semester": 3,
      });
    });

    test("validates year and semester before HTTP", () async {
      await expectLater(repository.fetchMyTimetable(0, 3), throwsArgumentError);
      await expectLater(
        repository.fetchMyTimetable(2026, 0),
        throwsArgumentError,
      );
      await expectLater(
        repository.fetchMyTimetable(2026, 5),
        throwsArgumentError,
      );

      expect(adapter.requests, isEmpty);
    });
  });

  test("create posts lectureIds without the legacy lectures key", () async {
    adapter.register("POST", "/$API_V2_TIMETABLES_URL", <String, dynamic>{
      "id": 9,
    });

    final id = await repository.create(
      year: 2026,
      semester: 3,
      lectureIds: <int>[1921750, 1921751],
    );

    expect(id, 9);
    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.method, "POST");
    expect(request.uri.path, "/$API_V2_TIMETABLES_URL");
    expect(request.queryParameters, isEmpty);
    expect(request.data, <String, dynamic>{
      "year": 2026,
      "semester": 3,
      "lectureIds": <int>[1921750, 1921751],
    });
    expect(request.data as Map<String, dynamic>, isNot(contains("lectures")));
  });

  test("create rejects a non-positive response id", () async {
    adapter.register("POST", "/$API_V2_TIMETABLES_URL", <String, dynamic>{
      "id": 0,
    });

    await expectLater(
      repository.create(year: 2026, semester: 3, lectureIds: <int>[]),
      throwsA(isA<FormatException>()),
    );

    expect(adapter.requests, hasLength(1));
  });

  for (final action in TimetableLectureAction.values) {
    test(
      "updateLecture ${action.name} patches then refetches the detail",
      () async {
        const summary = TimetableListItem(
          id: 7,
          name: "첫 시간표",
          year: 2026,
          semester: 3,
          timeTableOrder: 0,
        );
        final path = API_V2_TIMETABLE_DETAIL_URL.replaceFirst("{id}", "7");
        adapter.register("PATCH", "/$path", <String, dynamic>{"message": "ok"});
        adapter.register("GET", "/$path", detailFixture);

        final timetable = await repository.updateLecture(
          summary: summary,
          lectureId: 1921750,
          action: action,
        );

        expect(timetable.id, summary.id);
        expect(timetable.lectures.single.id, 1921750);
        expect(adapter.requests, hasLength(2));
        expect(
          adapter.requests.map((request) => request.method).toList(),
          <String>["PATCH", "GET"],
        );
        expect(
          adapter.requests.map((request) => request.uri.path).toList(),
          <String>["/$path", "/$path"],
        );
        expect(adapter.requests.first.data, <String, dynamic>{
          "lectureId": 1921750,
          "action": action.name,
        });
        expect(adapter.requests.last.data, isNull);
      },
    );
  }

  test("delete sends the timetable id in the v2 collection body", () async {
    adapter.register("DELETE", "/$API_V2_TIMETABLES_URL", <String, dynamic>{
      "message": "deleted",
    });

    await repository.delete(7);

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.method, "DELETE");
    expect(request.uri.path, "/$API_V2_TIMETABLES_URL");
    expect(request.queryParameters, isEmpty);
    expect(request.data, <String, dynamic>{"id": 7});
  });

  test(
    "create validates year, semester, and lecture ids before HTTP",
    () async {
      await expectLater(
        repository.create(year: 0, semester: 3, lectureIds: <int>[]),
        throwsArgumentError,
      );
      await expectLater(
        repository.create(year: 2026, semester: 0, lectureIds: <int>[]),
        throwsArgumentError,
      );
      await expectLater(
        repository.create(year: 2026, semester: 5, lectureIds: <int>[]),
        throwsArgumentError,
      );
      await expectLater(
        repository.create(year: 2026, semester: 3, lectureIds: <int>[0]),
        throwsArgumentError,
      );
      expect(adapter.requests, isEmpty);
    },
  );
}
