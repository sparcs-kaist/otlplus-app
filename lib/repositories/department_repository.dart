import "package:dio/dio.dart";
import "package:otlplus/constants/url.dart";

class DepartmentOption {
  const DepartmentOption({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory DepartmentOption.fromJson(Map<String, dynamic> json) {
    return DepartmentOption(
      id: json["id"] as int,
      name: json["name"] as String,
      code: json["code"] as String,
    );
  }
}

class DepartmentRepository {
  DepartmentRepository(this._dio);

  static const Set<String> _primaryFilterCodes = <String>{
    "HSS",
    "CE",
    "MSB",
    "ME",
    "PH",
    "BiS",
    "IE",
    "ID",
    "BS",
    "CBE",
    "MAS",
    "MS",
    "NQE",
    "TS",
    "CS",
    "EE",
    "AE",
    "CH",
    "BCE",
    "AI",
  };
  static const Set<int> _legacyMsbDepartmentIds = <int>{3844, 4299};

  final Dio _dio;
  Future<List<DepartmentOption>>? _optionsFuture;

  /// Fetches department options once per repository instance.
  ///
  /// Concurrent callers share the same request. Failed requests are not cached,
  /// allowing a later call to retry.
  Future<List<DepartmentOption>> fetchOptions() {
    return _optionsFuture ??= _loadOptions();
  }

  Future<List<DepartmentOption>> _loadOptions() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        API_V2_DEPARTMENT_OPTIONS_URL,
      );
      final data = response.data as Map<String, dynamic>;
      final departments = data["departments"] as List<dynamic>;

      return List<DepartmentOption>.unmodifiable(
        departments.map(
          (department) =>
              DepartmentOption.fromJson(department as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      // Intentional: department options are best-effort; empty fallback is valid.
      _optionsFuture = null;
      rethrow;
    }
  }

  Future<List<int>> resolveFilterCodes(Iterable<String> filterCodes) async {
    final selectedCodes = filterCodes.toSet();
    if (selectedCodes.isEmpty || selectedCodes.contains("ALL")) {
      return const <int>[];
    }

    final options = await fetchOptions();
    final resolvedIds = <int>{};
    final includesEtc = selectedCodes.contains("ETC");

    for (final option in options) {
      if (selectedCodes.contains(option.code) ||
          (includesEtc && !_primaryFilterCodes.contains(option.code))) {
        resolvedIds.add(option.id);
      }
    }

    if (selectedCodes.contains("MSB")) {
      resolvedIds.addAll(_legacyMsbDepartmentIds);
    }

    return resolvedIds.toList()..sort();
  }
}
