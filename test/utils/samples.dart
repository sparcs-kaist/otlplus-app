import 'package:otlplus/models/classtime.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/models/department.dart';
import 'package:otlplus/models/examtime.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/nested_course.dart';
import 'package:otlplus/models/nested_lecture.dart';
import 'package:otlplus/models/professor.dart';
import 'package:otlplus/models/review.dart';

class SampleClasstime {
  static final buildingCode = 'building_code';
  static final classroom = 'classroom';
  static final classroomEn = 'classroom_en';
  static final classroomShort = 'classroom_short';
  static final classroomShortEn = 'classroom_short_en';
  static final roomName = 'room_name';
  static final day = 1;
  static final begin = 2;
  static final end = 3;
  static final json =
      """
      {
        "building_code": "$buildingCode",
        "classroom": "$classroom",
        "classroom_en": "$classroomEn",
        "classroom_short": "$classroomShort",
        "classroom_short_en": "$classroomShortEn",
        "room_name": "$roomName",
        "day": $day,
        "begin": $begin,
        "end": $end
      }
      """;

  static final shared = Classtime(
    buildingCode: buildingCode,
    classroom: classroom,
    classroomEn: classroomEn,
    classroomShort: classroomShort,
    classroomShortEn: classroomShortEn,
    roomName: roomName,
    day: day,
    begin: begin,
    end: end,
  );
}

class SampleProfessor {
  static final name = "오승빈";
  static final nameEn = "Seungbin Oh";
  static final professorId = 1;
  static final reviewTotalWeight = 2.0;

  static final json =
      """{
    "name": "$name",
    "name_en": "$nameEn",
    "professor_id": $professorId,
    "review_total_weight": $reviewTotalWeight
  }""";

  static final shared = Professor(
    name: name,
    nameEn: nameEn,
    professorId: professorId,
    reviewTotalWeight: reviewTotalWeight,
  );
}

class SampleDepartment {
  static final id = 1;
  static final name = "";
  static final nameEn = "";
  static final code = "";

  static final json =
      """{
    "id": $id,
    "name": "$name",
    "name_en": "$nameEn",
    "code": "$code"
  }""";

  static final shared = Department(
    id: id,
    name: name,
    nameEn: nameEn,
    code: code,
  );
}

class SampleCourse {
  static final id = 1;
  static final oldCode = "oldCode";
  static final department = SampleDepartment.shared;
  static final type = "type";
  static final typeEn = "typeEn";
  static final title = "title";
  static final titleEn = "titleEn";
  static final summary = "summary";
  static final reviewTotalWeight = 2.0;
  static final professors = [SampleProfessor.shared];
  static final grade = 1.0;
  static final load = 2.0;
  static final speech = 3.0;
  static final userspecificIsRead = true;

  static final json =
      """{
      "id": $id,
      "old_code": "$oldCode",
      "department": ${SampleDepartment.json},
      "type": "$type",
      "type_en": "$typeEn",
      "title": "$title",
      "title_en": "$titleEn",
      "summary": "$summary",
      "review_total_weight": $reviewTotalWeight,
      "professors": [${SampleProfessor.json}],
      "grade": $grade,
      "load": $load,
      "speech": $speech,
      "userspecific_is_read": $userspecificIsRead
    }""";

  static final shared = Course(
    id: id,
    oldCode: oldCode,
    department: department,
    type: type,
    typeEn: typeEn,
    title: title,
    titleEn: titleEn,
    summary: summary,
    reviewTotalWeight: reviewTotalWeight,
    professors: professors,
    grade: grade,
    load: load,
    speech: speech,
    userspecificIsRead: userspecificIsRead,
  );

  static final nested = NestedCourse(
    id: id,
    oldCode: oldCode,
    type: type,
    typeEn: typeEn,
    title: title,
    titleEn: titleEn,
    summary: summary,
    reviewTotalWeight: reviewTotalWeight,
  );
}

class SampleExamtime {
  static final str = "";
  static final strEn = "";
  static final day = 1;
  static final begin = 2;
  static final end = 3;

  static final shared = Examtime(
    str: str,
    strEn: strEn,
    day: day,
    begin: begin,
    end: end,
  );
}

class SampleLecture {
  static final id = 1;
  static final title = "";
  static final titleEn = "";
  static final course = SampleCourse.shared.id;
  static final oldCode = "";
  static final classNo = '';
  static final year = 2021;
  static final semester = 3;
  static final code = '';
  static final department = 4;
  static final departmentCode = '';
  static final departmentName = '';
  static final departmentNameEn = '';
  static final type = '';
  static final typeEn = '';
  static final typeIdx = 1;
  static final limit = 4;
  static final numPeople = 5;
  static final isEnglish = true;
  static final credit = 1;
  static final creditAu = 1;
  static final commonTitle = "";
  static final commonTitleEn = "";
  static final classTitle = "";
  static final classTitleEn = "";
  static final reviewTotalWeight = 1.0;
  static final professors = [SampleProfessor.shared];
  static final grade = 2.0;
  static final load = 3.0;
  static final speech = 4.0;
  static final classtimes = [SampleClasstime.shared];
  static final examtimes = [SampleExamtime.shared];

  static final shared = Lecture(
    id: id,
    title: title,
    titleEn: titleEn,
    course: course,
    oldCode: oldCode,
    classNo: classNo,
    year: year,
    semester: semester,
    code: code,
    department: department,
    departmentCode: departmentCode,
    departmentName: departmentName,
    departmentNameEn: departmentNameEn,
    type: type,
    typeEn: typeEn,
    typeIdx: typeIdx,
    limit: limit,
    numPeople: numPeople,
    isEnglish: isEnglish,
    credit: credit,
    creditAu: creditAu,
    commonTitle: commonTitle,
    commonTitleEn: commonTitleEn,
    classTitle: classTitle,
    classTitleEn: classTitleEn,
    reviewTotalWeight: reviewTotalWeight,
    professors: professors,
    grade: grade,
    load: load,
    speech: speech,
    classtimes: classtimes,
    examtimes: examtimes,
  );

  static final nested = NestedLecture(
    id: id,
    title: title,
    titleEn: titleEn,
    course: course,
    oldCode: oldCode,
    classNo: classNo,
    year: year,
    semester: semester,
    code: code,
    department: department,
    departmentCode: departmentCode,
    departmentName: departmentName,
    departmentNameEn: departmentNameEn,
    type: type,
    typeEn: typeEn,
    limit: limit,
    numPeople: numPeople,
    isEnglish: isEnglish,
    credit: credit,
    creditAu: creditAu,
    commonTitle: commonTitle,
    commonTitleEn: commonTitleEn,
    classTitle: classTitle,
    classTitleEn: classTitleEn,
    reviewTotalWeight: reviewTotalWeight,
    professors: professors,
  );
}

class SampleReview {
  static final id = 1;
  static final course = SampleCourse.nested;
  static final lecture = SampleLecture.nested;
  static final content = "";
  static final like = 2;
  static final isDeleted = 0;
  static final grade = 1;
  static final load = 2;
  static final speech = 3;
  static final userspecificIsLiked = true;

  static final shared = Review(
    id: id,
    course: course,
    lecture: lecture,
    content: content,
    like: like,
    isDeleted: isDeleted,
    grade: grade,
    load: load,
    speech: speech,
    userspecificIsLiked: userspecificIsLiked,
  );
}
