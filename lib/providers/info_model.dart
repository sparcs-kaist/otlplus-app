import 'package:channel_talk_flutter/channel_talk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/models/timetable.dart';
import 'package:otlplus/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

const SCHEDULE_NAME = [
  "beginning",
  "end",
  "courseRegistrationPeriodStart",
  "courseRegistrationPeriodEnd",
  "courseAddDropPeriodEnd",
  "courseDropDeadline",
  "courseEvaluationDeadline",
  "gradePosting",
];

class InfoModel extends ChangeNotifier {
  bool _hasData = false;
  bool get hasData => _hasData;

  User? _user;
  User get user => _user!;

  List<Semester> _semesters = <Semester>[];
  List<Semester> get semesters => _semesters;

  List<Timetable> _currentSchedule = <Timetable>[];
  List<Timetable> get currentSchedule => _currentSchedule;

  Set<int> _years = <int>{};
  Set<int> get years => _years;

  InfoModel({bool forTest = false}) {
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
          reviews: []);
      _semesters = [
        Semester(
            year: 2000,
            semester: 1,
            beginning: DateTime(2000),
            end: DateTime(2001))
      ];
      _currentSchedule = [
        Timetable(id: 1, year: 2000, semester: 1, lectures: [])
      ];
    }
  }

  void clearData() {
    _user = null;
    _semesters = [];
    _currentSchedule = [];
    _years = {};
    _hasData = false;
    notifyListeners();
    _updateChannelTalkUser(null);
  }

  void _updateChannelTalkUser(User? user) {
    ChannelTalk.isBooted().then((isBooted) {
      if (isBooted == true) {
        if (user != null) {
          ChannelTalk.updateUser(
            name: "${user.firstName} ${user.lastName}",
            email: user.email,
            customAttributes: {
              "id": user.id,
              "studentId": user.studentId,
            },
          );
        } else {
          ChannelTalk.updateUser(
            name: "",
            email: "",
            customAttributes: {
              "id": 0,
              "studentId": "",
            },
          );
        }
      }
    });
  }

  Future<void> getInfo() async {
    try {
      if (!_hasData) {
        _semesters = await getSemesters();
        _years = _semesters.map((semester) => semester.year).toSet();
        _user = await getUser();
        if (_user != null) {
          _populateCurrentScheduleFromUser(_user!);
        }
        _hasData = true;
        _updateChannelTalkUser(_user);
        notifyListeners();
      }
    } catch (e) {
      print("Failed to get user info: $e");
      throw e;
    }
  }

  void _populateCurrentScheduleFromUser(User user) {
    Map<String, List<Lecture>> lecturesBySemester = {};
    for (var lecture in user.myTimetableLectures) {
      String key = "${lecture.year}-${lecture.semester}";
      if (lecturesBySemester[key] == null) {
        lecturesBySemester[key] = [];
      }
      lecturesBySemester[key]!.add(lecture);
    }

    _currentSchedule = lecturesBySemester.entries.map((entry) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final semester = int.parse(parts[1]);
      return Timetable(id: -1, year: year, semester: semester, lectures: entry.value);
    }).toList();

    _currentSchedule.sort((a, b) {
      int yearComp = a.year.compareTo(b.year);
      if (yearComp != 0) return yearComp;
      return a.semester.compareTo(b.semester);
    });
  }

  Future<List<Semester>> getSemesters() async {
    final response = await DioProvider().dio.get(API_SEMESTER_URL);
    final rawSemesters = response.data as List;
    return rawSemesters.map((semester) => Semester.fromJson(semester)).toList();
  }

  Future<User> getUser() async {
    final response = await DioProvider().dio.get(SESSION_INFO_URL);
    return User.fromJson(response.data);
  }

  Timetable getCurrentSchedule() {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    int semester = 1;
    if (month >= 7) {
      semester = 3;
    }

    try {
      return _currentSchedule.firstWhere(
        (timetable) => timetable.year == year && timetable.semester == semester
      );
    } catch (e) {
      return Timetable(id: -1, year: year, semester: semester, lectures: []);
    }
  }

  Future<void> deleteAccount() async {
    final pref = await SharedPreferences.getInstance();
    pref.setBool('hasAccount', false);
    _hasData = false;
    notifyListeners();
  }
}
