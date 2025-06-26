import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/filter.dart';
import 'package:otlplus/models/course.dart';

class CourseSearchModel extends ChangeNotifier {
  List<Course>? _courses;
  List<Course>? get courses => _courses;

  String _courseSearchText = '';
  String get courseSearchText => _courseSearchText;
  void setCourseSearchText(String text) {
    _courseSearchText = text;
  }

  Map<String, FilterGroupInfo> _courseFilter = {
    "departments": FilterGroupInfo(
        label: "department.department",
        isMultiSelect: true,
        options: [
          [
            CodeLabelPair(code: "HSS", label: "department.hss"),
            CodeLabelPair(code: "CE", label: "department.ce"),
            CodeLabelPair(code: "MSB", label: "department.msb"),
            CodeLabelPair(code: "ME", label: "department.me"),
          ],
          [
            CodeLabelPair(code: "PH", label: "department.ph"),
            CodeLabelPair(code: "BiS", label: "department.bis"),
            CodeLabelPair(code: "IE", label: "department.ie"),
            CodeLabelPair(code: "ID", label: "department.id"),
          ],
          [
            CodeLabelPair(code: "BS", label: "department.bs"),
            CodeLabelPair(code: "CBE", label: "department.cbe"),
            CodeLabelPair(code: "MAS", label: "department.mas"),
            CodeLabelPair(code: "MS", label: "department.ms"),
          ],
          [
            CodeLabelPair(code: "NQE", label: "department.nqe"),
            CodeLabelPair(code: "TS", label: "department.ts"),
            CodeLabelPair(code: "CS", label: "department.cs"),
            CodeLabelPair(code: "EE", label: "department.ee"),
          ],
          [
            CodeLabelPair(code: "AE", label: "department.ae"),
            CodeLabelPair(code: "CH", label: "department.ch"),
            CodeLabelPair(code: "ETC", label: "department.etc"),
          ]
        ]),
    "types":
        FilterGroupInfo(label: "type.type", isMultiSelect: true, options: [
      [
        CodeLabelPair(code: "BR", label: "type.br"),
        CodeLabelPair(code: "BE", label: "type.be"),
        CodeLabelPair(code: "MR", label: "type.mr"),
        CodeLabelPair(code: "ME", label: "type.me"),
      ],
      [
        CodeLabelPair(code: "MGC", label: "type.mgc"),
        CodeLabelPair(code: "HSE", label: "type.hse"),
        CodeLabelPair(code: "GR", label: "type.gr"),
        CodeLabelPair(code: "EG", label: "type.eg"),
      ],
      [
        CodeLabelPair(code: "OE", label: "type.oe"),
        CodeLabelPair(code: "ETC", label: "type.etc"),
      ]
    ]),
    "levels": FilterGroupInfo(
        label: "level.level",
        isMultiSelect: true,
        options: [
          [
            CodeLabelPair(code: "100", label: "level.100s"),
            CodeLabelPair(code: "200", label: "level.200s"),
            CodeLabelPair(code: "300", label: "level.300s"),
            CodeLabelPair(code: "400", label: "level.400s"),
          ],
          [
            CodeLabelPair(code: "ETC", label: "level.etc"),
          ]
        ]),
    "terms": FilterGroupInfo(
        label: "term.term",
        isMultiSelect: false,
        type: "slider",
        options: [
          [CodeLabelPair(code: "ALL", label: "term.all", selected: true)],
          [
            CodeLabelPair(
              code: "3",
              label: "term.3_years",
              selected: false,
            )
          ],
          [
            CodeLabelPair(
              code: "2",
              label: "term.2_years",
              selected: false,
            )
          ],
          [
            CodeLabelPair(
              code: "1",
              label: "term.1_years",
              selected: false,
            )
          ],
        ])
  };
  get courseFilter => _courseFilter;

  void resetCourseFilter() {
    _courses = null;
    _courseSearchText = '';
    _courseFilter.values.forEach((e) {
      if (e.isMultiSelect)
        e.options.forEach((b) => b.forEach((c) => c.selected = false));
      else {
        e.options.forEach((b) => b.forEach((c) => c.selected = false));
        e.options.first.first.selected = true;
      }
    });
    updateCourseSearchquery();
    notifyListeners();
  }

  void setCourseFilterSelected(String varient, String code, bool selected) {
    assert(['departments', 'types', 'levels', 'terms'].contains(varient));
    _courseFilter[varient]!
        .options
        .expand((i) => i)
        .firstWhere((i) => i.code == code)
        .selected = selected;
    notifyListeners();
  }

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  Text? _courseSearchquery;
  Text get courseSearchquery => (_courseSearchquery == null)
      ? Text(
          "common.search_hint".tr(),
          style: bodyRegular.copyWith(color: OTLColor.grayA),
        )
      : _courseSearchquery!;
  void updateCourseSearchquery() {
    List<String> _selectedFilters = (_courseFilter.map((k, v) => MapEntry(
        k,
        (v.isMultiSelect == false && v.options.first.first.selected == true) ||
                v.options.expand((i) => i).every((i) => i.selected == true)
            ? Iterable<String>.empty()
            : v.options
                .expand((i) => i)
                .where((i) => i.selected == true)
                .map((i) => i.label)))).values.expand((i) => i).toList();
    if (_selectedFilters.length == 0 && _courseSearchText.length == 0) {
      _courseSearchquery = null;
    } else {
      _courseSearchquery = Text.rich(
        TextSpan(
          style: bodyRegular.copyWith(color: OTLColor.grayA),
          children: [
            TextSpan(
              text: _courseSearchText.isEmpty ? '' : '"$_courseSearchText"',
            ),
            TextSpan(
              children: [
                if (_selectedFilters.length > 0 && _courseSearchText.length > 0)
                  TextSpan(text: ", "),
                TextSpan(
                  text: _selectedFilters.map((e) => e.tr()).join(", "),
                ),
              ],
            )
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Future<bool> courseSearch({String order = "DEF", double tune = 3}) async {
    _courseFilter.forEach((k, v) {
      if (v.options.expand((i) => i).every((i) => i.selected == false)) {
        if (v.isMultiSelect == true)
          v.options.expand((i) => i).forEach((j) {
            // j.selected = true;
          });
        else
          v.options.first.first.selected = true;
      }
    });
    List<CodeLabelPair> dep = _courseFilter['departments']!
            .options
            .expand((i) => i)
            .every((i) => i.selected == false)
        ? []
        : _courseFilter['departments']!
            .options
            .expand((i) => i)
            .where((i) => i.selected == true)
            .toList();
    List<CodeLabelPair> typ = _courseFilter['types']!
            .options
            .expand((i) => i)
            .every((i) => i.selected == false)
        ? []
        : _courseFilter['types']!
            .options
            .expand((i) => i)
            .where((i) => i.selected == true)
            .toList();
    List<CodeLabelPair> lev = _courseFilter['levels']!
            .options
            .expand((i) => i)
            .every((i) => i.selected == false)
        ? []
        : _courseFilter['levels']!
            .options
            .expand((i) => i)
            .where((i) => i.selected == true)
            .toList();
    CodeLabelPair term = _courseFilter['terms']!
        .options
        .expand((i) => i)
        .firstWhere((i) => i.selected == true);
    if (dep.length == 0 &&
        typ.length == 0 &&
        lev.length == 0 &&
        _courseSearchText.length == 0) return false;
    Future(() async {
      updateCourseSearchquery();
      _isSearching = true;
      notifyListeners();
      try {
        final response = await DioProvider()
            .dio
            .getUri(Uri(path: API_COURSE_URL, queryParameters: {
              "keyword": _courseSearchText,
              "department":
                  dep.length == 0 ? ['ALL'] : dep.map((i) => i.code).toList(),
              "type":
                  typ.length == 0 ? ['ALL'] : typ.map((i) => i.code).toList(),
              "level":
                  lev.length == 0 ? ['ALL'] : lev.map((i) => i.code).toList(),
              "term": term.code,
            }));

        final rawCourses = response.data as List;
        _courses = rawCourses.map((course) => Course.fromJson(course)).toList();

        switch (order) {
          case "RAT":
            final avgRatings = _courses!.fold<double>(
                    0, (acc, val) => acc + val.grade + val.load + val.speech) /
                _courses!.length;
            _courses!.sort((a, b) {
              final aRating =
                  ((a.grade + a.load + a.speech) * a.reviewTotalWeight +
                          avgRatings * tune) /
                      (a.reviewTotalWeight + tune);
              final bRating =
                  ((b.grade + b.load + b.speech) * b.reviewTotalWeight +
                          avgRatings * tune) /
                      (b.reviewTotalWeight + tune);
              return bRating.compareTo(aRating);
            });
            break;
          case "GRA":
            final avgRatings =
                _courses!.fold<double>(0, (acc, val) => acc + val.grade) /
                    _courses!.length;
            _courses!.sort((a, b) {
              final aRating =
                  (a.grade * a.reviewTotalWeight + avgRatings * tune) /
                      (a.reviewTotalWeight + tune);
              final bRating =
                  (b.grade * b.reviewTotalWeight + avgRatings * tune) /
                      (b.reviewTotalWeight + tune);
              return bRating.compareTo(aRating);
            });
            break;
          case "LOA":
            final avgRatings =
                _courses!.fold<double>(0, (acc, val) => acc + val.load) /
                    _courses!.length;
            _courses!.sort((a, b) {
              final aRating =
                  (a.load * a.reviewTotalWeight + avgRatings * tune) /
                      (a.reviewTotalWeight + tune);
              final bRating =
                  (b.load * b.reviewTotalWeight + avgRatings * tune) /
                      (b.reviewTotalWeight + tune);
              return bRating.compareTo(aRating);
            });
            break;
          case "SPE":
            final avgRatings =
                _courses!.fold<double>(0, (acc, val) => acc + val.speech) /
                    _courses!.length;
            _courses!.sort((a, b) {
              final aRating =
                  (a.speech * a.reviewTotalWeight + avgRatings * tune) /
                      (a.reviewTotalWeight + tune);
              final bRating =
                  (b.speech * b.reviewTotalWeight + avgRatings * tune) /
                      (b.reviewTotalWeight + tune);
              return bRating.compareTo(aRating);
            });
            break;
        }
      } catch (exception) {
        print(exception);
      }

      _isSearching = false;
      notifyListeners();
    });
    return true;
  }
}
