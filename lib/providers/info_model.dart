import 'package:channel_talk_flutter/channel_talk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
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
  final TelemetryCoordinator? _telemetry;

  InfoModel({bool forTest = false, TelemetryCoordinator? telemetry})
    : _telemetry = telemetry {
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
          year: 2000,
          semester: 1,
          beginning: DateTime(2000),
          end: DateTime(2001),
        ),
      ];
      _currentSchedule = {
        "semester": _semesters.first,
        "name": 'home.schedule.beginning',
        "time": DateTime.now(),
      };
    }
  }

  bool _hasData = false;
  bool get hasData => _hasData;

  bool _hasError = false;
  bool get hasError => _hasError;

  User? _user;
  User get user => _user!;

  List<Semester> _semesters = <Semester>[];
  List<Semester> get semesters => _semesters;

  Map<String, dynamic>? _currentSchedule;
  Map<String, dynamic>? get currentSchedule => _currentSchedule;

  Set<int> _years = <int>{};
  Set<int> get years => _years;

  void clearData() {
    // _user = null;
    _semesters = [];
    _currentSchedule = null;
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
            customAttributes: {"id": user.id, "studentId": user.studentId},
          );
        } else {
          ChannelTalk.updateUser(
            name: "",
            email: "",
            customAttributes: {"id": 0, "studentId": ""},
          );
        }
      }
    });
  }

  /// Loads the signed-in user's info. On failure [hasError] is set instead of
  /// throwing; session-level failures are handled by the Dio interceptor.
  Future<void> getInfo() async {
    if (_hasData) return;
    if (_hasError) {
      _hasError = false;
      notifyListeners();
    }
    try {
      _semesters = await getSemesters();
      _years = _semesters.map((semester) => semester.year).toSet();
      _user = await getUser();
      _currentSchedule = getCurrentSchedule();
      _hasData = true;
      _updateChannelTalkUser(_user);
      notifyListeners();
    } catch (error, stackTrace) {
      await _telemetry?.recordNonFatal(
        error,
        stackTrace,
        operation: 'load_user_info',
      );
      _hasError = true;
      notifyListeners();
    }
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

  Map<String, dynamic>? getCurrentSchedule() {
    final now = DateTime.now();
    final schedules = _semesters
        .map(
          (semester) => SCHEDULE_NAME.map((name) {
            final time = semester.toJson()[name];
            if (time == null) return null;
            return <String, dynamic>{
              "semester": semester,
              "name": 'home.schedule.$name',
              "time": time,
            };
          }),
        )
        .expand((e) => e)
        .where((e) => e != null)
        .toList();
    schedules.sort((a, b) => a!["time"].compareTo(b!["time"]));

    return schedules.firstWhere(
      (e) => e!["time"].isAfter(now),
      orElse: () => null,
    );
  }

  Future<void> deleteAccount() async {
    final pref = await SharedPreferences.getInstance();
    pref.setBool('hasAccount', false);
    _hasData = false;
    notifyListeners();
  }
}
