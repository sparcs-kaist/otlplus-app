import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/filter.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/repositories/department_repository.dart';
import 'package:otlplus/repositories/lecture_repository.dart';

class LectureSearchModel extends ChangeNotifier {
  LectureSearchModel([
    LectureRepository? lectureRepository,
    DepartmentRepository? departmentRepository,
  ]) : _lectureRepository =
           lectureRepository ?? LectureRepository(DioProvider().dio),
       _departmentRepository =
           departmentRepository ?? DepartmentRepository(DioProvider().dio);

  final LectureRepository _lectureRepository;
  final DepartmentRepository _departmentRepository;

  bool get resultOpened => _lectures != null || _isSearching;

  List<List<Lecture>>? _lectures;
  List<List<Lecture>>? get lectures => _lectures ?? [];

  String _lectureSearchText = '';
  String get lectureSearchText => _lectureSearchText;
  void setLectureSearchText(String text) {
    _lectureSearchText = text;
  }

  Map<String, FilterGroupInfo> _lectureFilter = {
    "departments": FilterGroupInfo(
      label: "department.department".tr(),
      isMultiSelect: true,
      options: [
        [
          CodeLabelPair(code: "HSS", label: "department.hss".tr()),
          CodeLabelPair(code: "CE", label: "department.ce".tr()),
          CodeLabelPair(code: "MSB", label: "department.msb".tr()),
          CodeLabelPair(code: "ME", label: "department.me".tr()),
        ],
        [
          CodeLabelPair(code: "PH", label: "department.ph".tr()),
          CodeLabelPair(code: "BiS", label: "department.bis".tr()),
          CodeLabelPair(code: "IE", label: "department.ie".tr()),
          CodeLabelPair(code: "ID", label: "department.id".tr()),
        ],
        [
          CodeLabelPair(code: "BS", label: "department.bs".tr()),
          CodeLabelPair(code: "CBE", label: "department.cbe".tr()),
          CodeLabelPair(code: "MAS", label: "department.mas".tr()),
          CodeLabelPair(code: "MS", label: "department.ms".tr()),
        ],
        [
          CodeLabelPair(code: "NQE", label: "department.nqe".tr()),
          CodeLabelPair(code: "TS", label: "department.ts".tr()),
          CodeLabelPair(code: "CS", label: "department.cs".tr()),
          CodeLabelPair(code: "EE", label: "department.ee".tr()),
        ],
        [
          CodeLabelPair(code: "AE", label: "department.ae".tr()),
          CodeLabelPair(code: "CH", label: "department.ch".tr()),
          CodeLabelPair(code: "ETC", label: "department.etc".tr()),
        ],
      ],
    ),
    "types": FilterGroupInfo(
      label: "type.type".tr(),
      isMultiSelect: true,
      options: [
        [
          CodeLabelPair(code: "BR", label: "type.br".tr()),
          CodeLabelPair(code: "BE", label: "type.be".tr()),
          CodeLabelPair(code: "MR", label: "type.mr".tr()),
          CodeLabelPair(code: "ME", label: "type.me".tr()),
        ],
        [
          CodeLabelPair(code: "MGC", label: "type.mgc".tr()),
          CodeLabelPair(code: "HSE", label: "type.hse".tr()),
          CodeLabelPair(code: "GR", label: "type.gr".tr()),
          CodeLabelPair(code: "EG", label: "type.eg".tr()),
        ],
        [
          CodeLabelPair(code: "OE", label: "type.oe".tr()),
          CodeLabelPair(code: "ETC", label: "type.etc".tr()),
        ],
      ],
    ),
    "levels": FilterGroupInfo(
      label: "level.level".tr(),
      isMultiSelect: true,
      options: [
        [
          CodeLabelPair(code: "100", label: "level.100s".tr()),
          CodeLabelPair(code: "200", label: "level.200s".tr()),
          CodeLabelPair(code: "300", label: "level.300s".tr()),
          CodeLabelPair(code: "400", label: "level.400s".tr()),
        ],
        [CodeLabelPair(code: "ETC", label: "level.etc".tr())],
      ],
    ),
  };
  get lectureFilter => _lectureFilter;

  void resetLectureFilter() {
    _requestGeneration += 1;
    _lectures = null;
    _lectureSearchText = '';
    _isSearching = false;
    _error = null;
    for (final group in _lectureFilter.values) {
      for (final option in group.options.expand((row) => row)) {
        option.selected = false;
      }
      if (!group.isMultiSelect) group.options.first.first.selected = true;
    }
    updateLectureSearchqeury();
    notifyListeners();
  }

  void setLectureFilterSelected(String varient, String code, bool selected) {
    assert(['departments', 'types', 'levels'].contains(varient));
    _lectureFilter[varient]!.options
            .expand((i) => i)
            .firstWhere((i) => i.code == code)
            .selected =
        selected;
    notifyListeners();
  }

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  Object? _error;
  Object? get error => _error;

  int _requestGeneration = 0;

  Text _lectureSearchquery = Text.rich(TextSpan());
  Text get lectureSearchquery => _lectureSearchquery;
  void updateLectureSearchqeury() {
    List<String> _selectedFilters = (_lectureFilter.map(
      (k, v) => MapEntry(
        k,
        (v.isMultiSelect == false && v.options.first.first.selected == true) ||
                v.options.expand((i) => i).every((i) => i.selected == true)
            ? Iterable<String>.empty()
            : v.options
                  .expand((i) => i)
                  .where((i) => i.selected == true)
                  .map((i) => i.label),
      ),
    )).values.expand((i) => i).toList();
    _lectureSearchquery = Text.rich(
      TextSpan(
        style: bodyRegular.copyWith(color: OTLColor.grayA),
        children: [
          TextSpan(
            text: _lectureSearchText.isEmpty ? '' : '"$_lectureSearchText"',
          ),
          TextSpan(
            children: [
              if (_selectedFilters.length > 0 && _lectureSearchText.length > 0)
                TextSpan(text: ", "),
              TextSpan(text: _selectedFilters.join(", ")),
            ],
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void lectureClear() {
    _requestGeneration += 1;
    _lectures = null;
    _isSearching = false;
    _error = null;
    notifyListeners();
  }

  Text createQuery(
    String? keyword,
    List<CodeLabelPair>? department,
    List<CodeLabelPair>? type,
    List<CodeLabelPair>? level,
    CodeLabelPair? term,
  ) {
    List<String> filterOptions = [
      ...(department ?? [])
          .where((i) => i.selected == true)
          .map((i) => i.label)
          .toList(),
      ...(type ?? [])
          .where((i) => i.selected == true)
          .map((i) => i.label)
          .toList(),
      ...(level ?? [])
          .where((i) => i.selected == true)
          .map((i) => i.label)
          .toList(),
      if (term != null && term.code != 'ALL') term.label,
    ];
    return Text.rich(
      TextSpan(
        style: TextStyle(fontSize: 14, height: 1.2, letterSpacing: 0.15),
        children: [
          TextSpan(
            text: keyword,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: OTLColor.gray0,
            ),
          ),
          if (filterOptions.length > 0)
            TextSpan(
              style: TextStyle(color: OTLColor.grayA),
              children: [
                if ((keyword ?? '').length > 0) TextSpan(text: ", "),
                TextSpan(text: (filterOptions).join(", ")),
              ],
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<bool> lectureSearch(Semester semester) {
    final departmentCodes = _selectedCodes('departments');
    final typeCodes = _mapTypeCodes(_selectedCodes('types'));
    final levelCodes = _mapLevelCodes(_selectedCodes('levels'));
    final keyword = _lectureSearchText;
    final hasSearchCriteria =
        departmentCodes.isNotEmpty ||
        typeCodes.isNotEmpty ||
        levelCodes.isNotEmpty ||
        keyword.isNotEmpty;
    if (!hasSearchCriteria) return Future<bool>.value(false);

    final generation = ++_requestGeneration;
    updateLectureSearchqeury();
    _isSearching = true;
    _error = null;
    notifyListeners();

    unawaited(
      _loadLectures(
        generation: generation,
        semester: semester,
        keyword: keyword,
        departmentCodes: departmentCodes,
        typeCodes: typeCodes,
        levelCodes: levelCodes,
      ),
    );
    return Future<bool>.value(true);
  }

  Future<void> _loadLectures({
    required int generation,
    required Semester semester,
    required String keyword,
    required List<String> departmentCodes,
    required List<String> typeCodes,
    required List<int> levelCodes,
  }) async {
    try {
      final departmentIds = await _departmentRepository.resolveFilterCodes(
        departmentCodes,
      );
      if (generation != _requestGeneration) return;

      final lectures = await _lectureRepository.search(
        LectureSearchQuery(
          year: semester.year,
          semester: semester.semester,
          keyword: keyword,
          departments: departmentIds,
          types: typeCodes,
          levels: levelCodes,
        ),
      );
      if (generation != _requestGeneration) return;

      final courseIds = lectures.map((lecture) => lecture.course).toSet();
      _lectures = courseIds
          .map(
            (courseId) => lectures
                .where((lecture) => lecture.course == courseId)
                .toList(growable: false),
          )
          .where((courseLectures) => courseLectures.isNotEmpty)
          .toList(growable: false);
    } catch (caughtError) {
      if (generation != _requestGeneration) return;
      _error = caughtError;
    } finally {
      if (generation == _requestGeneration) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  List<String> _selectedCodes(String groupName) {
    return _lectureFilter[groupName]!.options
        .expand((row) => row)
        .where((option) => option.selected)
        .map((option) => option.code)
        .toList(growable: false);
  }
}

const Map<String, String> _v2TypeCodeByLegacyCode = <String, String>{
  'BR': 'BR',
  'BE': 'BE',
  'MR': 'MR',
  'ME': 'ME',
  'MGC': 'MGC',
  'HSE': 'HSE',
  'GR': 'GR',
  'EG': 'EG',
  'OE': 'OE',
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
    if (code == 'ETC') {
      levels.addAll(const <int>[500, 600, 700, 800, 900]);
      continue;
    }
    final level = int.tryParse(code);
    if (level != null) levels.add(level);
  }
  return levels;
}
