import "dart:async";

import "package:flutter/foundation.dart";
import "package:otlplus/models/course.dart";
import "package:otlplus/models/filter.dart";
import "package:otlplus/repositories/course_repository.dart";
import "package:otlplus/repositories/department_repository.dart";

class CourseSearchModel extends ChangeNotifier {
  CourseSearchModel(
    CourseRepository courseRepository,
    DepartmentRepository departmentRepository,
  ) : _courseRepository = courseRepository,
      _departmentRepository = departmentRepository;

  final CourseRepository _courseRepository;
  final DepartmentRepository _departmentRepository;

  List<Course>? _courses;
  List<Course>? get courses {
    final courses = _courses;
    return courses == null ? null : List<Course>.unmodifiable(courses);
  }

  String _searchText = "";
  String get searchText => _searchText;

  void setSearchText(String text) {
    _searchText = text;
  }

  final Map<String, FilterGroupInfo> _courseFilter = <String, FilterGroupInfo>{
    "departments": FilterGroupInfo(
      label: "department.department",
      isMultiSelect: true,
      options: <List<CodeLabelPair>>[
        <CodeLabelPair>[
          CodeLabelPair(code: "HSS", label: "department.hss"),
          CodeLabelPair(code: "CE", label: "department.ce"),
          CodeLabelPair(code: "MSB", label: "department.msb"),
          CodeLabelPair(code: "ME", label: "department.me"),
        ],
        <CodeLabelPair>[
          CodeLabelPair(code: "PH", label: "department.ph"),
          CodeLabelPair(code: "BiS", label: "department.bis"),
          CodeLabelPair(code: "IE", label: "department.ie"),
          CodeLabelPair(code: "ID", label: "department.id"),
        ],
        <CodeLabelPair>[
          CodeLabelPair(code: "BS", label: "department.bs"),
          CodeLabelPair(code: "CBE", label: "department.cbe"),
          CodeLabelPair(code: "MAS", label: "department.mas"),
          CodeLabelPair(code: "MS", label: "department.ms"),
        ],
        <CodeLabelPair>[
          CodeLabelPair(code: "NQE", label: "department.nqe"),
          CodeLabelPair(code: "TS", label: "department.ts"),
          CodeLabelPair(code: "CS", label: "department.cs"),
          CodeLabelPair(code: "EE", label: "department.ee"),
        ],
        <CodeLabelPair>[
          CodeLabelPair(code: "AE", label: "department.ae"),
          CodeLabelPair(code: "CH", label: "department.ch"),
          CodeLabelPair(code: "BCE", label: "department.bce"),
          CodeLabelPair(code: "AI", label: "department.ai"),
          CodeLabelPair(code: "ETC", label: "department.etc"),
        ],
      ],
    ),
    "types": FilterGroupInfo(
      label: "type.type",
      isMultiSelect: true,
      options: <List<CodeLabelPair>>[
        <CodeLabelPair>[
          CodeLabelPair(code: "BR", label: "type.br"),
          CodeLabelPair(code: "BE", label: "type.be"),
          CodeLabelPair(code: "MR", label: "type.mr"),
          CodeLabelPair(code: "ME", label: "type.me"),
        ],
        <CodeLabelPair>[
          CodeLabelPair(code: "MGC", label: "type.mgc"),
          CodeLabelPair(code: "HSE", label: "type.hse"),
          CodeLabelPair(code: "GR", label: "type.gr"),
          CodeLabelPair(code: "EG", label: "type.eg"),
        ],
        <CodeLabelPair>[
          CodeLabelPair(code: "OE", label: "type.oe"),
          CodeLabelPair(code: "ETC", label: "type.etc"),
        ],
      ],
    ),
    "levels": FilterGroupInfo(
      label: "level.level",
      isMultiSelect: true,
      options: <List<CodeLabelPair>>[
        <CodeLabelPair>[
          CodeLabelPair(code: "100", label: "level.100s"),
          CodeLabelPair(code: "200", label: "level.200s"),
          CodeLabelPair(code: "300", label: "level.300s"),
          CodeLabelPair(code: "400", label: "level.400s"),
        ],
        <CodeLabelPair>[CodeLabelPair(code: "ETC", label: "level.etc")],
      ],
    ),
    "terms": FilterGroupInfo(
      label: "term.term",
      isMultiSelect: false,
      type: "slider",
      options: <List<CodeLabelPair>>[
        <CodeLabelPair>[
          CodeLabelPair(code: "ALL", label: "term.all", selected: true),
        ],
        <CodeLabelPair>[CodeLabelPair(code: "3", label: "term.3_years")],
        <CodeLabelPair>[CodeLabelPair(code: "2", label: "term.2_years")],
        <CodeLabelPair>[CodeLabelPair(code: "1", label: "term.1_years")],
      ],
    ),
  };

  Map<String, FilterGroupInfo> get courseFilter => _courseFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Retained for the dictionary page's existing public API.
  bool get isSearching => _isLoading;

  Object? _error;
  Object? get error => _error;

  int _requestGeneration = 0;

  List<String> get selectedFilterLabelKeys => List<String>.unmodifiable(
    _courseFilter.values.expand(_selectedLabelsForSummary),
  );

  void resetCourseFilter() {
    _requestGeneration += 1;
    _courses = null;
    _searchText = "";
    _isLoading = false;
    _error = null;
    for (final group in _courseFilter.values) {
      for (final option in group.options.expand((row) => row)) {
        option.selected = false;
      }
      if (!group.isMultiSelect) group.options.first.first.selected = true;
    }
    notifyListeners();
  }

  void setCourseFilterSelected(String variant, String code, bool selected) {
    assert(
      <String>{"departments", "types", "levels", "terms"}.contains(variant),
    );
    _courseFilter[variant]!.options
            .expand((row) => row)
            .firstWhere((option) => option.code == code)
            .selected =
        selected;
    notifyListeners();
  }

  Future<bool> courseSearch({String order = "DEF"}) {
    final departmentCodes = _selectedCodes("departments");
    final typeCodes = _mapTypeCodes(_selectedCodes("types"));
    final levelCodes = _mapLevelCodes(_selectedCodes("levels"));
    final term = _selectedTerm();
    final keyword = _searchText;
    final hasSearchCriteria =
        departmentCodes.isNotEmpty ||
        typeCodes.isNotEmpty ||
        levelCodes.isNotEmpty ||
        term != null ||
        keyword.isNotEmpty;
    if (!hasSearchCriteria) return Future<bool>.value(false);

    final generation = ++_requestGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // The search page uses this result to navigate immediately; repository
    // completion is represented by [isLoading], [error], and [courses].
    unawaited(
      _loadCourses(
        generation: generation,
        keyword: keyword,
        departmentCodes: departmentCodes,
        typeCodes: typeCodes,
        levelCodes: levelCodes,
        term: term,
        order: order,
      ),
    );
    return Future<bool>.value(true);
  }

  Future<void> _loadCourses({
    required int generation,
    required String keyword,
    required List<String> departmentCodes,
    required List<String> typeCodes,
    required List<int> levelCodes,
    required int? term,
    required String order,
  }) async {
    try {
      final departmentIds = await _departmentRepository.resolveFilterCodes(
        departmentCodes,
      );
      if (generation != _requestGeneration) return;
      final result = await _courseRepository.search(
        CourseSearchQuery(
          keyword: keyword,
          types: typeCodes,
          departments: departmentIds,
          levels: levelCodes,
          term: term,
          order: _mapLegacyOrder(order),
        ),
      );
      if (generation != _requestGeneration) return;
      _courses = result.courses;
    } catch (caughtError) {
      if (generation != _requestGeneration) return;
      _error = caughtError;
    } finally {
      if (generation == _requestGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  List<String> _selectedCodes(String groupName) {
    return _courseFilter[groupName]!.options
        .expand((row) => row)
        .where((option) => option.selected)
        .map((option) => option.code)
        .toList(growable: false);
  }

  int? _selectedTerm() {
    final selected = _selectedCodes("terms");
    if (selected.isEmpty || selected.first == "ALL") return null;
    return int.tryParse(selected.first);
  }
}

Iterable<String> _selectedLabelsForSummary(FilterGroupInfo group) {
  final options = group.options.expand((row) => row);
  if ((!group.isMultiSelect && group.options.first.first.selected) ||
      options.every((option) => option.selected)) {
    return const <String>[];
  }
  return options
      .where((option) => option.selected)
      .map((option) => option.label);
}

const Map<String, String> _v2TypeCodeByLegacyCode = <String, String>{
  "BR": "BR",
  "BE": "BE",
  "MR": "MR",
  "ME": "ME",
  "MGC": "MGC",
  "HSE": "HSE",
  "GR": "GR",
  "EG": "EG",
  "OE": "OE",
};

List<String> _mapTypeCodes(Iterable<String> legacyCodes) {
  return legacyCodes
      .map((code) => _v2TypeCodeByLegacyCode[code])
      .whereType<String>()
      .toList(growable: false);
}

List<int> _mapLevelCodes(Iterable<String> legacyCodes) {
  final levels = <int>[];
  for (final code in legacyCodes) {
    if (code == "ETC") {
      levels.addAll(const <int>[500, 600, 700, 800, 900]);
      continue;
    }
    final level = int.tryParse(code);
    if (level != null) levels.add(level);
  }
  return levels;
}

const Map<String, String> _v2OrderByLegacyOrder = <String, String>{
  "DEF": "code",
  "RAT": "popular",
  "GRA": "popular",
  "LOA": "popular",
  "SPE": "popular",
};

String _mapLegacyOrder(String legacyOrder) {
  // v2 no longer exposes grade/load/speech rating fields. Mapping all legacy
  // rating dimensions to the server's popularity order preserves useful ranking
  // without silently sorting on compatibility-zero model fields. DEF and
  // unknown values use the v2 course-code order.
  return _v2OrderByLegacyOrder[legacyOrder] ?? "code";
}
