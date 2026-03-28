import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/models/timetable.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/utils/export_file.dart';

class TimetableModel extends ChangeNotifier {
  late User _user;
  User get user => _user;

  late List<Semester> _semesters;

  late int _selectedSemesterIndex;
  Semester get selectedSemester => _semesters[_selectedSemesterIndex];

  late List<Timetable> _timetables;
  List<Timetable> get timetables => _timetables;

  Lecture? _tempLecture;
  Lecture? get tempLecture => _tempLecture;

  void setTempLecture(Lecture? lecture) {
    _tempLecture = lecture;
    notifyListeners();
  }

  int _selectedTimetableIndex = 0;
  int get selectedIndex => _selectedTimetableIndex;

  Timetable get currentTimetable => _timetables[_selectedTimetableIndex];

  int _selectedModeIndex = 0;
  int get selectedMode => _selectedModeIndex;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  TimetableModel({bool forTest = false}) {
    if (forTest) {
      _user = User(
        id: 0,
        email: "email",
        studentId: "studentId",
        firstName: "firstName",
        lastName: "lastName",
        majors: [],
        departments: [],
        myTimetableLectures: [],
        reviewWritableLectures: [],
        reviews: [],
      );
      _semesters = [
        Semester(
          year: 2024,
          semester: 3,
          beginning: DateTime.now(),
          end: DateTime.now(),
        ),
      ];
      _timetables = [
        Timetable(id: 0, lectures: []),
        Timetable(id: 1, lectures: []),
      ];
      _selectedSemesterIndex = 0;
    }
  }

  void loadSemesters({required User user, required List<Semester> semesters}) {
    _user = user;
    _semesters = semesters;
    _selectedSemesterIndex = semesters.length - 1;
    notifyListeners();
    _loadTimetable();
  }

  get canGoPreviousSemester => _selectedSemesterIndex > 0;

  bool goPreviousSemester() {
    if (canGoPreviousSemester) {
      _selectedSemesterIndex--;
      notifyListeners();
      _loadTimetable();
      return true;
    }
    return false;
  }

  get canGoNextSemester => _selectedSemesterIndex < _semesters.length - 1;

  bool goNextSemester() {
    if (canGoNextSemester) {
      _selectedSemesterIndex++;
      notifyListeners();
      _loadTimetable();
      return true;
    }
    return false;
  }

  void setIndex(int index) {
    _selectedTimetableIndex = index;
    notifyListeners();
  }

  void setMode(int index) {
    _selectedModeIndex = index;
    notifyListeners();
  }

  Future<bool> _loadTimetable() async {
    try {
      final response = await DioProvider().dio.get(
        API_TIMETABLE_URL.replaceFirst("{user_id}", _user.id.toString()),
        queryParameters: {
          "year": selectedSemester.year,
          "semester": selectedSemester.semester,
        },
      );

      List<dynamic> rawTimetables = response.data as List;

      if (rawTimetables.isEmpty) {
        _selectedTimetableIndex = -1;
        _timetables = [];
        await createTimetable();
        await _loadTimetable();
        return true;
      }

      _timetables = rawTimetables
          .map((timetable) => Timetable.fromJson(timetable))
          .toList();

      List<Lecture> myLecturesList = _user.myTimetableLectures
          .where(
            (lecture) =>
                lecture.year == selectedSemester.year &&
                lecture.semester == selectedSemester.semester,
          )
          .toList();
      Timetable myTimetable = Timetable(id: -1, lectures: myLecturesList);
      _timetables.insert(0, myTimetable);
      _selectedTimetableIndex = _selectedTimetableIndex == 0 ? 0 : 1;
      _isLoaded = true;
      notifyListeners();
      return true;
    } catch (exception) {
      print(exception);
    }
    return false;
  }

  Future<bool> createTimetable({List<Lecture>? lectures}) async {
    try {
      final response = await DioProvider().dio.post(
        API_TIMETABLE_URL.replaceFirst("{user_id}", user.id.toString()),
        data: {
          "year": selectedSemester.year,
          "semester": selectedSemester.semester,
          "lectures": (lectures == null)
              ? []
              : lectures.map((lecture) => lecture.id).toList(),
        },
      );
      final timetable = Timetable.fromJson(response.data);
      _timetables.add(timetable);
      _selectedTimetableIndex = _timetables.length - 1;
      notifyListeners();
      return true;
    } catch (exception) {
      print(exception);
    }
    return false;
  }

  Future<bool> addLecture({
    required Lecture lecture,
    required FutureOr<bool> Function() noOverlap,
    required FutureOr<bool> Function(Iterable<Lecture>) onOverlap,
  }) async {
    try {
      final overlappedLectures = currentTimetable.lectures.where(
        (timetableLecture) => lecture.classtimes.any(
          (thisClasstime) => timetableLecture.classtimes.any(
            (classtime) =>
                (classtime.day == thisClasstime.day) &&
                (classtime.begin < thisClasstime.end) &&
                (classtime.end > thisClasstime.begin),
          ),
        ),
      );

      if (overlappedLectures.length > 0) {
        if (!await onOverlap(overlappedLectures)) return false;

        for (final lecture in overlappedLectures) {
          await DioProvider().dio.post(
            API_TIMETABLE_REMOVE_LECTURE_URL
                .replaceFirst("{user_id}", user.id.toString())
                .replaceFirst("{timetable_id}", currentTimetable.id.toString()),
            data: {"lecture": lecture.id},
          );
        }
        currentTimetable.lectures.removeWhere(overlappedLectures.contains);
      } else if (!await noOverlap())
        return false;

      final response = await DioProvider().dio.post(
        API_TIMETABLE_ADD_LECTURE_URL
            .replaceFirst("{user_id}", user.id.toString())
            .replaceFirst("{timetable_id}", currentTimetable.id.toString()),
        data: {"lecture": lecture.id},
      );
      final timetable = Timetable.fromJson(response.data);
      _timetables[_selectedTimetableIndex] = timetable;
      notifyListeners();
      return true;
    } catch (exception) {
      print(exception);
    }
    return false;
  }

  Future<bool> removeLecture({required Lecture lecture}) async {
    try {
      final response = await DioProvider().dio.post(
        API_TIMETABLE_REMOVE_LECTURE_URL
            .replaceFirst("{user_id}", user.id.toString())
            .replaceFirst("{timetable_id}", currentTimetable.id.toString()),
        data: {"lecture": lecture.id},
      );
      final timetable = Timetable.fromJson(response.data);
      _timetables[_selectedTimetableIndex] = timetable;
      notifyListeners();
      return true;
    } catch (exception) {
      print(exception);
    }
    return false;
  }

  Future<bool> deleteTimetable() async {
    try {
      if (_timetables.length <= 1) return false;

      await DioProvider().dio.delete(
        API_TIMETABLE_URL.replaceFirst("{user_id}", user.id.toString()) +
            "/" +
            currentTimetable.id.toString(),
        data: {},
      );

      _timetables.remove(currentTimetable);
      if (_selectedTimetableIndex > 0) _selectedTimetableIndex--;
      notifyListeners();
      return true;
    } catch (exception) {
      print(exception);
    }
    return false;
  }

  Future<bool> shareTimetable(ShareType type, String language) async {
    try {
      final response = await DioProvider().dio.get(
        API_SHARE_URL.replaceFirst(
          '{share_type}',
          type == ShareType.image ? 'image' : 'ical',
        ),
        queryParameters: {
          'timetable': currentTimetable.id,
          'year': selectedSemester.year,
          'semester': selectedSemester.semester,
          'language': language,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      writeFile(type, response.data);
      return true;
    } catch (exception) {
      print(exception);
    }
    return false;
  }
}
