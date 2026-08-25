import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/models/timetable.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/repositories/timetable_repository.dart';
import 'package:otlplus/utils/export_file.dart';

typedef TimetableFileWriter =
    Future<void> Function(ShareType type, Uint8List? bytes);

class TimetableModel extends ChangeNotifier {
  TimetableModel({
    TimetableRepository? repository,
    Dio? legacyShareDio,
    TimetableFileWriter? fileWriter,
    bool forTest = false,
  }) : _repository = repository ?? TimetableRepository(DioProvider().dio),
       _legacyShareDio = legacyShareDio ?? DioProvider().dio,
       _fileWriter = fileWriter ?? writeFile {
    if (forTest) {
      _user = User(
        id: 0,
        email: 'email',
        studentId: 'studentId',
        firstName: 'firstName',
        lastName: 'lastName',
        majors: [],
        departments: [],
        myTimetableLectures: [],
        reviewWritableLectures: [],
        reviews: [],
      );
      _semesters = [
        Semester(
          year: 2024,
          semester: Season.fall.code,
          beginning: DateTime.now(),
          end: DateTime.now(),
        ),
      ];
      _summaries = [
        const TimetableListItem(
          id: 1,
          name: 'Timetable 1',
          year: 2024,
          semester: 3,
          timeTableOrder: 0,
        ),
      ];
      _timetables = [
        Timetable(id: -1, lectures: []),
        Timetable(id: 1, lectures: []),
      ];
      _selectedSemesterIndex = 0;
      _isLoaded = true;
    }
  }

  final TimetableRepository _repository;

  // Image/iCal export has not moved to TimetableRepository yet. Keep this
  // isolated boundary only for the retained share endpoints.
  final Dio _legacyShareDio;
  final TimetableFileWriter _fileWriter;

  late User _user;
  User get user => _user;

  List<Semester> _semesters = <Semester>[];

  int _selectedSemesterIndex = 0;
  Semester get selectedSemester => _semesters[_selectedSemesterIndex];
  Season get selectedSeason {
    final season = Season.fromCode(selectedSemester.semester);
    if (season == null) {
      throw StateError(
        'Unsupported semester code: ${selectedSemester.semester}',
      );
    }
    return season;
  }

  List<TimetableListItem> _summaries = <TimetableListItem>[];
  List<TimetableListItem> get summaries =>
      List<TimetableListItem>.unmodifiable(_summaries);

  List<Timetable> _timetables = <Timetable>[];
  List<Timetable> get timetables => List<Timetable>.unmodifiable(_timetables);

  Lecture? _tempLecture;
  Lecture? get tempLecture => _tempLecture;

  void setTempLecture(Lecture? lecture) {
    _tempLecture = lecture;
    notifyListeners();
  }

  static const int myTimetableIndex = 0;
  static const int _firstSavedTimetableIndex = myTimetableIndex + 1;

  int _selectedTimetableIndex = myTimetableIndex;
  int get selectedIndex => _selectedTimetableIndex;
  bool get isMyTimetable => isMyTimetableIndex(_selectedTimetableIndex);

  bool isMyTimetableIndex(int index) => index == myTimetableIndex;

  Timetable get currentTimetable => _timetables[_selectedTimetableIndex];

  TimetableViewMode _selectedMode = TimetableViewMode.classes;
  TimetableViewMode get selectedMode => _selectedMode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _loadFailed = false;
  bool get loadFailed => _loadFailed;

  Object? _error;
  Object? get error => _error;

  int _loadRequestId = 0;

  Future<void> loadSemesters({
    required User user,
    required List<Semester> semesters,
  }) async {
    _user = user;
    _semesters = List<Semester>.of(semesters);
    if (_semesters.isEmpty) {
      _setLoadError(StateError('At least one semester is required'));
      return;
    }
    _selectedSemesterIndex = _semesters.length - 1;
    await _loadTimetable();
  }

  bool get canGoPreviousSemester => _selectedSemesterIndex > 0;

  bool goPreviousSemester() {
    if (!canGoPreviousSemester) return false;
    _selectedSemesterIndex--;
    unawaited(_loadTimetable());
    return true;
  }

  bool get canGoNextSemester => _selectedSemesterIndex < _semesters.length - 1;

  bool goNextSemester() {
    if (!canGoNextSemester) return false;
    _selectedSemesterIndex++;
    unawaited(_loadTimetable());
    return true;
  }

  void setIndex(int index) {
    if (index < 0 || index >= _timetables.length) return;
    _selectedTimetableIndex = index;
    notifyListeners();
  }

  void setMode(TimetableViewMode mode) {
    _selectedMode = mode;
    notifyListeners();
  }

  Future<bool> _loadTimetable() async {
    final requestId = ++_loadRequestId;
    final selectServerTimetable = !isMyTimetable;
    _isLoading = true;
    _isLoaded = false;
    _loadFailed = false;
    _error = null;
    _selectedTimetableIndex = myTimetableIndex;
    _summaries = <TimetableListItem>[];
    _timetables = <Timetable>[];
    notifyListeners();

    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        _repository.fetchMyTimetable(
          selectedSemester.year,
          selectedSeason.code,
        ),
        _repository.fetchBySemester(selectedSemester.year, selectedSeason.code),
      ]);
      final primary = results[0] as Timetable;
      var collection = results[1] as TimetableCollection;
      if (requestId != _loadRequestId) return false;
      if (collection.summaries.isEmpty) {
        await _repository.create(
          year: selectedSemester.year,
          semester: selectedSeason.code,
          lectureIds: <int>[],
        );
        collection = await _repository.fetchBySemester(
          selectedSemester.year,
          selectedSeason.code,
        );
        if (collection.summaries.isEmpty) {
          throw StateError('Created timetable was missing from the refetch');
        }
      }
      if (requestId != _loadRequestId) return false;

      _applyCollection(
        primary,
        collection,
        selectServerTimetable: selectServerTimetable,
      );
      _isLoading = false;
      _isLoaded = true;
      notifyListeners();
      return true;
    } catch (exception) {
      if (requestId != _loadRequestId) return false;
      _setLoadError(exception);
      return false;
    }
  }

  void _applyCollection(
    Timetable primary,
    TimetableCollection collection, {
    int? preferredTimetableId,
    bool selectServerTimetable = false,
  }) {
    if (collection.summaries.isEmpty) {
      throw StateError('Timetable collection must not be empty');
    }
    if (collection.summaries.length != collection.timetables.length) {
      throw StateError(
        'Timetable summaries and details must have equal length',
      );
    }
    for (var index = 0; index < collection.summaries.length; index++) {
      if (collection.summaries[index].id != collection.timetables[index].id) {
        throw StateError('Timetable summary/detail order is inconsistent');
      }
    }

    _summaries = List<TimetableListItem>.of(collection.summaries);
    _timetables = <Timetable>[primary, ...collection.timetables];

    if (preferredTimetableId != null) {
      final summaryIndex = _summaries.indexWhere(
        (summary) => summary.id == preferredTimetableId,
      );
      _selectedTimetableIndex = summaryIndex < 0
          ? myTimetableIndex
          : summaryIndex + _firstSavedTimetableIndex;
    } else if (selectServerTimetable && _summaries.isNotEmpty) {
      _selectedTimetableIndex = _firstSavedTimetableIndex;
    } else {
      _selectedTimetableIndex = myTimetableIndex;
    }
  }

  void _setLoadError(Object exception) {
    _error = exception;
    _isLoading = false;
    _isLoaded = false;
    _loadFailed = true;
    _selectedTimetableIndex = myTimetableIndex;
    _summaries = <TimetableListItem>[];
    _timetables = <Timetable>[];
    notifyListeners();
  }

  Future<void> retryLoad() async {
    await _loadTimetable();
  }

  Future<bool> createTimetable({List<Lecture>? lectures}) async {
    if (_semesters.isEmpty || !_isLoaded || _timetables.isEmpty) return false;
    try {
      _error = null;
      final id = await _repository.create(
        year: selectedSemester.year,
        semester: selectedSeason.code,
        lectureIds: (lectures ?? <Lecture>[])
            .map((lecture) => lecture.id)
            .toList(growable: false),
      );
      final collection = await _repository.fetchBySemester(
        selectedSemester.year,
        selectedSeason.code,
      );
      _applyCollection(_timetables.first, collection, preferredTimetableId: id);
      _isLoaded = true;
      _loadFailed = false;
      notifyListeners();
      return !isMyTimetable;
    } catch (exception) {
      _error = exception;
      notifyListeners();
      return false;
    }
  }

  List<Lecture> overlappingLectures(Lecture lecture) {
    if (!_hasEditableTimetable) return <Lecture>[];
    return currentTimetable.lectures
        .where(
          (timetableLecture) => lecture.classtimes.any(
            (thisClasstime) => timetableLecture.classtimes.any(
              (classtime) =>
                  classtime.day == thisClasstime.day &&
                  classtime.begin < thisClasstime.end &&
                  classtime.end > thisClasstime.begin,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<TimetableAddResult> addLecture({
    required Lecture lecture,
    bool replaceOverlaps = false,
  }) async {
    if (!_hasEditableTimetable) return TimetableAddResult.failed;
    final hadError = _error != null;
    _error = null;
    final overlaps = overlappingLectures(lecture);
    if (overlaps.isNotEmpty && !replaceOverlaps) {
      if (hadError) notifyListeners();
      return TimetableAddResult.overlap;
    }

    try {
      for (final overlap in overlaps) {
        final updated = await _repository.updateLecture(
          summary: _currentSummary,
          lectureId: overlap.id,
          action: TimetableLectureAction.delete,
        );
        _replaceCurrentTimetable(updated);
      }
      final updated = await _repository.updateLecture(
        summary: _currentSummary,
        lectureId: lecture.id,
        action: TimetableLectureAction.add,
      );
      _replaceCurrentTimetable(updated);
      notifyListeners();
      return TimetableAddResult.added;
    } catch (exception) {
      _error = exception;
      notifyListeners();
      return TimetableAddResult.failed;
    }
  }

  Future<bool> removeLecture({required Lecture lecture}) async {
    if (!_hasEditableTimetable) return false;
    try {
      _error = null;
      final updated = await _repository.updateLecture(
        summary: _currentSummary,
        lectureId: lecture.id,
        action: TimetableLectureAction.delete,
      );
      _replaceCurrentTimetable(updated);
      notifyListeners();
      return true;
    } catch (exception) {
      _error = exception;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTimetable() async {
    if (!_hasEditableTimetable) return false;
    try {
      _error = null;
      final deletedIndex = _selectedTimetableIndex;
      await _repository.delete(currentTimetable.id);
      _summaries.removeAt(deletedIndex - _firstSavedTimetableIndex);
      _timetables.removeAt(deletedIndex);
      _selectedTimetableIndex = deletedIndex - _firstSavedTimetableIndex;
      if (_selectedTimetableIndex >= _timetables.length) {
        _selectedTimetableIndex = _timetables.length - 1;
      }
      notifyListeners();
      return true;
    } catch (exception) {
      _error = exception;
      notifyListeners();
      return false;
    }
  }

  // The dedicated my-timetable response is read-only. The server collection
  // contains only editable user-created timetable summaries.
  bool get _hasEditableTimetable =>
      !isMyTimetable &&
      _selectedTimetableIndex < _timetables.length &&
      _selectedTimetableIndex - _firstSavedTimetableIndex < _summaries.length;

  TimetableListItem get _currentSummary =>
      _summaries[_selectedTimetableIndex - _firstSavedTimetableIndex];

  void _replaceCurrentTimetable(Timetable timetable) {
    if (timetable.id != _currentSummary.id) {
      throw StateError('Updated timetable id does not match its summary');
    }
    _timetables[_selectedTimetableIndex] = timetable;
  }

  Future<bool> shareTimetable(ShareType type, String language) async {
    try {
      final response = await _legacyShareDio.get(
        API_SHARE_URL.replaceFirst(
          '{share_type}',
          type == ShareType.image ? 'image' : 'ical',
        ),
        queryParameters: {
          'timetable': currentTimetable.id,
          'year': selectedSemester.year,
          'semester': selectedSeason.code,
          'language': language,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      final data = response.data;
      final bytes = data == null
          ? null
          : data is Uint8List
          ? data
          : Uint8List.fromList(data as List<int>);
      await _fileWriter(type, bytes);
      return true;
    } catch (exception) {
      _error = exception;
      notifyListeners();
      return false;
    }
  }
}
