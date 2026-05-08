import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/theme/context_ext.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:provider/provider.dart';

const TYPES_SHORT = ["br", "be", "mr", "me", "hse", "etc"];
const LETTERS = [
  "?",
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
];

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
    int targetNum = lectures.fold(
      0,
      (acc, lecture) =>
          acc +
          ((lecture.reviewTotalWeight > 0)
              ? (lecture.credit + lecture.creditAu)
              : 0),
    );
    double grade = lectures.fold(
      0,
      (acc, lecture) =>
          acc +
          ((lecture.reviewTotalWeight > 0)
              ? (lecture.grade * (lecture.credit + lecture.creditAu))
              : 0),
    );
    double load = lectures.fold(
      0,
      (acc, lecture) =>
          acc +
          ((lecture.reviewTotalWeight > 0)
              ? (lecture.load * (lecture.credit + lecture.creditAu))
              : 0),
    );
    double speech = lectures.fold(
      0,
      (acc, lecture) =>
          acc +
          ((lecture.reviewTotalWeight > 0)
              ? (lecture.speech * (lecture.credit + lecture.creditAu))
              : 0),
    );
    if (tempLecture != null) {
      typeCredit[tempLecture.typeIdx] +=
          (tempLecture.credit + tempLecture.creditAu);
      allCreditCredit += tempLecture.credit;
      allAuCredit += tempLecture.creditAu;
      targetNum += ((tempLecture.reviewTotalWeight > 0)
          ? (tempLecture.credit + tempLecture.creditAu)
          : 0);
      grade += ((tempLecture.reviewTotalWeight > 0)
          ? (tempLecture.grade * (tempLecture.credit + tempLecture.creditAu))
          : 0);
      load += ((tempLecture.reviewTotalWeight > 0)
          ? (tempLecture.load * (tempLecture.credit + tempLecture.creditAu))
          : 0);
      speech += ((tempLecture.reviewTotalWeight > 0)
          ? (tempLecture.speech * (tempLecture.credit + tempLecture.creditAu))
          : 0);
    }

    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: context.colors.backgroundPageDefault),
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
                context,
                'timetable.summary.${TYPES_SHORT[index]}'.tr(),
                typeCredit[index],
                tempLecture?.typeIdx == index,
              ),
            ),
          ),
          _buildScore(
            context,
            'timetable.summary.credit'.tr(),
            allCreditCredit.toString(),
            tempLecture != null && tempLecture.credit > 0,
          ),
          _buildScore(
            context,
            "AU",
            allAuCredit.toString(),
            tempLecture != null && tempLecture.creditAu > 0,
          ),
          _buildScore(
            context,
            'timetable.summary.grade'.tr(),
            targetNum > 0 ? LETTERS[(grade / targetNum).round()] : "?",
            tempLecture != null && tempLecture.grade > 0,
          ),
          _buildScore(
            context,
            'timetable.summary.load'.tr(),
            targetNum > 0 ? LETTERS[(load / targetNum).round()] : "?",
            tempLecture != null && tempLecture.load > 0,
          ),
          _buildScore(
            context,
            'timetable.summary.speech'.tr(),
            targetNum > 0 ? LETTERS[(speech / targetNum).round()] : "?",
            tempLecture != null && tempLecture.speech > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildScore(
    BuildContext context,
    String title,
    String content,
    bool highlight,
  ) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 26,
            child: Text(
              content,
              style: context.texts.bigBold.copyWith(
                color: highlight
                    ? context.colors.highlightDefault
                    : context.colors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 17,
            child: Text(
              title,
              style: context.texts.small.copyWith(
                color: highlight
                    ? context.colors.highlightDefault
                    : context.colors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttribute(
    BuildContext context,
    String title,
    int value,
    bool highlight,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            title,
            style: context.texts.smallBold.copyWith(
              color: highlight
                  ? context.colors.highlightDefault
                  : context.colors.textDark,
            ),
          ),
        ),
        SizedBox(
          width: 17,
          child: Text(
            value.toString(),
            style: context.texts.small.copyWith(
              color: highlight
                  ? context.colors.highlightDefault
                  : context.colors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
