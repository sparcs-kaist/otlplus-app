import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/filter.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/semester.dart';

class LectureSearchModel extends ChangeNotifier {
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
    _lectures = null;
    _lectureSearchText = '';
    _lectureFilter.values.forEach((e) {
      if (e.isMultiSelect)
        e.options.forEach((b) => b.forEach((c) => c.selected = false));
      else {
        e.options.forEach((b) => b.forEach((c) => c.selected = false));
        e.options.first.first.selected = true;
      }
    });
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
    _lectures = null;
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

  Future<bool> lectureSearch(Semester semester) async {
    _lectureFilter.forEach((k, v) {
      if (v.options.expand((i) => i).every((i) => i.selected == false)) {
        if (v.isMultiSelect == true)
          v.options.expand((i) => i).forEach((j) {
            // j.selected = true;
          });
        else
          v.options.first.first.selected = true;
      }
    });
    List<CodeLabelPair> dep =
        _lectureFilter['departments']!.options
            .expand((i) => i)
            .every((i) => i.selected == false)
        ? []
        : _lectureFilter['departments']!.options
              .expand((i) => i)
              .where((i) => i.selected == true)
              .toList();
    List<CodeLabelPair> typ =
        _lectureFilter['types']!.options
            .expand((i) => i)
            .every((i) => i.selected == false)
        ? []
        : _lectureFilter['types']!.options
              .expand((i) => i)
              .where((i) => i.selected == true)
              .toList();
    List<CodeLabelPair> lev =
        _lectureFilter['levels']!.options
            .expand((i) => i)
            .every((i) => i.selected == false)
        ? []
        : _lectureFilter['levels']!.options
              .expand((i) => i)
              .where((i) => i.selected == true)
              .toList();
    if (dep.length == 0 &&
        typ.length == 0 &&
        lev.length == 0 &&
        _lectureSearchText.length == 0)
      return false;
    Future(() async {
      updateLectureSearchqeury();
      _isSearching = true;
      notifyListeners();
      try {
        final response = await DioProvider().dio.getUri(
          Uri(
            path: API_LECTURE_URL,
            queryParameters: {
              "year": semester.year.toString(),
              "semester": semester.semester.toString(),
              "keyword": _lectureSearchText,
              "department": dep.length == 0
                  ? ['ALL']
                  : dep.map((i) => i.code).toList(),
              "type": typ.length == 0
                  ? ['ALL']
                  : typ.map((i) => i.code).toList(),
              "level": lev.length == 0
                  ? ['ALL']
                  : lev.map((i) => i.code).toList(),
            },
          ),
        );

        final rawLectures = response.data as List;
        final lectures = rawLectures.map(
          (lecture) => Lecture.fromJson(lecture),
        );
        final courseIds = lectures.map((lecture) => lecture.course).toSet();

        _lectures = courseIds
            .map(
              (course) => lectures
                  .where((lecture) => lecture.course == course)
                  .toList(),
            )
            .where((course) => course.length > 0)
            .toList();
      } catch (exception) {
        print(exception);
      }

      _isSearching = false;
      notifyListeners();
    });
    return true;
  }
}
