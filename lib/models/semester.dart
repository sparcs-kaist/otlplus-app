class Semester {
  final int year;
  final int semester;
  final DateTime beginning;
  final DateTime end;
  final DateTime? courseDesciptionSubmission;
  final DateTime? courseRegistrationPeriodStart;
  final DateTime? courseRegistrationPeriodEnd;
  final DateTime? courseAddDropPeriodEnd;
  final DateTime? courseDropDeadline;
  final DateTime? courseEvaluationDeadline;
  final DateTime? gradePosting;

  Semester({
    required this.year,
    required this.semester,
    required this.beginning,
    required this.end,
    this.courseDesciptionSubmission,
    this.courseRegistrationPeriodStart,
    this.courseRegistrationPeriodEnd,
    this.courseAddDropPeriodEnd,
    this.courseDropDeadline,
    this.courseEvaluationDeadline,
    this.gradePosting,
  });

  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Semester && other.year == year && other.semester == semester);

  int get hashCode => year.hashCode ^ semester.hashCode;

  Semester.fromJson(Map<String, dynamic> json)
    : year = json['year'],
      semester = json['semester'],
      beginning = DateTime.parse(json['beginning']),
      end = DateTime.parse(json['end']),
      courseDesciptionSubmission = DateTime.tryParse(
        json['courseDesciptionSubmission'] ?? "",
      ),
      courseRegistrationPeriodStart = DateTime.tryParse(
        json['courseRegistrationPeriodStart'] ?? "",
      ),
      courseRegistrationPeriodEnd = DateTime.tryParse(
        json['courseRegistrationPeriodEnd'] ?? "",
      ),
      courseAddDropPeriodEnd = DateTime.tryParse(
        json['courseAddDropPeriodEnd'] ?? "",
      ),
      courseDropDeadline = DateTime.tryParse(json['courseDropDeadline'] ?? ""),
      courseEvaluationDeadline = DateTime.tryParse(
        json['courseEvaluationDeadline'] ?? "",
      ),
      gradePosting = DateTime.tryParse(json['gradePosting'] ?? "");

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data['year'] = this.year;
    data['semester'] = this.semester;
    data['beginning'] = this.beginning;
    data['end'] = this.end;
    data['courseDesciptionSubmission'] = this.courseDesciptionSubmission;
    data['courseRegistrationPeriodStart'] = this.courseRegistrationPeriodStart;
    data['courseRegistrationPeriodEnd'] = this.courseRegistrationPeriodEnd;
    data['courseAddDropPeriodEnd'] = this.courseAddDropPeriodEnd;
    data['courseDropDeadline'] = this.courseDropDeadline;
    data['courseEvaluationDeadline'] = this.courseEvaluationDeadline;
    data['gradePosting'] = this.gradePosting;
    return data;
  }
}
