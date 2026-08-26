import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:otlplus/constants/url.dart";
import "package:otlplus/repositories/department_repository.dart";

import "../utils/fake_http.dart";

class CountingHttpAdapter extends FakeHttpAdapter {
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requestCount += 1;
    return super.fetch(options, requestStream, cancelFuture);
  }
}

void main() {
  const exactPrimaryIds = <String, int>{
    "HSS": 9948,
    "CE": 709,
    "ME": 9942,
    "PH": 623,
    "BiS": 850,
    "IE": 1197,
    "ID": 625,
    "BS": 733,
    "CBE": 701,
    "MAS": 833,
    "MS": 732,
    "NQE": 639,
    "TS": 15784,
    "CS": 9945,
    "EE": 9947,
    "AE": 9944,
    "CH": 620,
  };

  late CountingHttpAdapter adapter;
  late DepartmentRepository repository;

  setUp(() async {
    final fixture =
        jsonDecode(
              await File(
                "test/fixtures/v2/department_options.json",
              ).readAsString(),
            )
            as Map<String, dynamic>;
    adapter = CountingHttpAdapter();
    adapter.register("GET", "/$API_V2_DEPARTMENT_OPTIONS_URL", fixture);
    final dio = Dio(BaseOptions(baseUrl: "http://test/"))
      ..httpClientAdapter = adapter;
    repository = DepartmentRepository(dio);
  });

  test("fetches typed department options from the v2 endpoint", () async {
    final options = await repository.fetchOptions();

    expect(options, hasLength(21));
    final physics = options.singleWhere((option) => option.code == "PH");
    expect(physics.id, 623);
    expect(physics.name, "물리학과");
  });

  test("resolves every exact primary code to its matching ID", () async {
    for (final entry in exactPrimaryIds.entries) {
      expect(
        await repository.resolveFilterCodes(<String>[entry.key]),
        <int>[entry.value],
        reason: entry.key,
      );
    }
  });

  test("supplements absent legacy MSB with both production IDs", () async {
    final options = await repository.fetchOptions();
    expect(options.any((option) => option.code == "MSB"), isFalse);

    expect(await repository.resolveFilterCodes(const <String>["MSB"]), <int>[
      3844,
      4299,
    ]);
  });

  test(
    "resolves the brain-cognitive and ai graduate codes as primary",
    () async {
      expect(await repository.resolveFilterCodes(const <String>["BCE"]), <int>[
        16412,
      ]);
      expect(await repository.resolveFilterCodes(const <String>["AI"]), <int>[
        16413,
      ]);
    },
  );

  test("resolves ETC to all options outside explicit primary codes", () async {
    expect(await repository.resolveFilterCodes(const <String>["ETC"]), <int>[
      7001,
      7002,
    ]);
  });

  test("shares one department options request across resolver calls", () async {
    await Future.wait(<Future<List<int>>>[
      repository.resolveFilterCodes(const <String>["PH"]),
      repository.resolveFilterCodes(const <String>["CS"]),
    ]);

    expect(adapter.requestCount, 1);
  });

  test("treats empty or ALL selections as no department filter", () async {
    expect(await repository.resolveFilterCodes(const <String>[]), isEmpty);
    expect(await repository.resolveFilterCodes(const <String>["ALL"]), isEmpty);
  });

  test("returns a stable sorted unique union for mixed selections", () async {
    expect(
      await repository.resolveFilterCodes(const <String>[
        "ETC",
        "PH",
        "MSB",
        "PH",
        "ETC",
      ]),
      <int>[623, 3844, 4299, 7001, 7002],
    );
  });
}
