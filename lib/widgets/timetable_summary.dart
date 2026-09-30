import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:provider/provider.dart';

const TYPES_SHORT = ["br", "be", "mr", "me", "hse", "etc"];
const LETTERS = [
  "F",
  "F",
  "F",
  "D-",
  "D",
  "D+",
  "C-",
  "C",
  "C+",
  "B-",
  "B",
  "B+",
  "A-",
  "A",
  "A+",
  "A+",
  "A+",
  "A+",
];

String _scoreLetter(double total, int count) {
  if (count == 0) return '?';
  final score = (total / count) / 3;
  final index = (score * 3).floor().clamp(0, LETTERS.length - 1);
  return LETTERS[index];
}

class TimetableSummary extends StatelessWidget {
  const TimetableSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lectures = context.select<TimetableModel, List<Lecture>>(
      (model) => model.currentTimetable.lectures,
    );
    final tempLecture = context.select<TimetableModel, Lecture?>(
      (model) => model.tempLecture,
    );
    List<int> typeCredit = List.generate(
      6,
      (int i) => lectures
          .where((lecture) => lecture.typeIdx == i)
          .fold<int>(
            0,
            (acc, lecture) => acc + lecture.credit + lecture.creditAu,
          ),
    );
    int allCreditCredit = lectures.fold<int>(
      0,
      (acc, lecture) => acc + lecture.credit,
    );
    int allAuCredit = lectures.fold<int>(
      0,
      (acc, lecture) => acc + lecture.creditAu,
    );
    final scoredLectures = [...lectures, if (tempLecture != null) tempLecture]
        .where(
          (lecture) =>
              lecture.grade != 0 || lecture.load != 0 || lecture.speech != 0,
        );
    var targetNum = 0;
    var grade = 0.0;
    var load = 0.0;
    var speech = 0.0;
    for (final lecture in scoredLectures) {
      targetNum++;
      grade += lecture.grade;
      load += lecture.load;
      speech += lecture.speech;
    }
    if (tempLecture != null) {
      typeCredit[tempLecture.typeIdx] +=
          (tempLecture.credit + tempLecture.creditAu);
      allCreditCredit += tempLecture.credit;
      allAuCredit += tempLecture.creditAu;
    }

    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: OTLColor.pinksLight),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.only(right: 3),
            child: GridView.builder(
              itemCount: 6,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                mainAxisExtent: 45,
              ),
              itemBuilder: (_, index) => _buildAttribute(
                'timetable.summary.${TYPES_SHORT[index]}'.tr(),
                typeCredit[index],
                tempLecture?.typeIdx == index,
              ),
            ),
          ),
          _buildScore(
            'timetable.summary.credit'.tr(),
            allCreditCredit.toString(),
            tempLecture != null && tempLecture.credit > 0,
          ),
          _buildScore(
            "AU",
            allAuCredit.toString(),
            tempLecture != null && tempLecture.creditAu > 0,
          ),
          _buildScore(
            'timetable.summary.grade'.tr(),
            _scoreLetter(grade, targetNum),
            tempLecture != null && tempLecture.grade > 0,
          ),
          _buildScore(
            'timetable.summary.load'.tr(),
            _scoreLetter(load, targetNum),
            tempLecture != null && tempLecture.load > 0,
          ),
          _buildScore(
            'timetable.summary.speech'.tr(),
            _scoreLetter(speech, targetNum),
            tempLecture != null && tempLecture.speech > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildScore(String title, String content, bool highlight) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 26,
            child: Text(
              content,
              style: titleBold.copyWith(
                color: highlight ? OTLColor.pinksMain : OTLColor.gray0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 17,
            child: Text(
              title,
              style: labelRegular.copyWith(
                color: highlight ? OTLColor.pinksMain : OTLColor.gray0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttribute(String title, int value, bool highlight) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            title,
            style: labelBold.copyWith(
              color: highlight ? OTLColor.pinksMain : OTLColor.gray0,
            ),
          ),
        ),
        SizedBox(
          width: 17,
          child: Text(
            value.toString(),
            style: labelRegular.copyWith(
              color: highlight ? OTLColor.pinksMain : OTLColor.gray0,
            ),
          ),
        ),
      ],
    );
  }
}
