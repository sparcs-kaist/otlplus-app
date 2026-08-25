import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/extensions/semester.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/models/user.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/lecture_simple_block.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:provider/provider.dart';

class MyReviewPage extends StatelessWidget {
  static String route = 'my_review_page';

  const MyReviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<InfoModel>().user;
    final targetSemesters =
        user.reviewWritableLectures
            .map(
              (lecture) => Semester(
                year: lecture.year,
                semester: lecture.semester,
                beginning: DateTime.now(),
                end: DateTime.now(),
              ),
            )
            .toSet()
            .toList()
          ..sort(
            (a, b) => ((a.year != b.year)
                ? (b.year - a.year)
                : (b.semester - a.semester)),
          );

    final entries = <_ReviewListEntry>[];
    for (final semester in targetSemesters) {
      entries.add(_SemesterHeaderEntry(semester));
      final lectures = user.reviewWritableLectures
          .where(
            (lecture) =>
                lecture.year == semester.year &&
                lecture.semester == semester.semester,
          )
          .toList();

      for (int index = 0; index < lectures.length; index += 2) {
        entries.add(
          _LectureRowEntry(
            first: lectures[index],
            second: index + 1 < lectures.length ? lectures[index + 1] : null,
            isLastInSemester: index + 2 >= lectures.length,
          ),
        );
      }
    }

    return OTLScaffold(
      child: OTLLayout(
        middle: Text('user.my_review'.tr(), style: titleBold),
        body: ColoredBox(
          color: OTLColor.grayF,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = entries[index];
                    return switch (entry) {
                      _SemesterHeaderEntry(:final semester) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(semester.title, style: labelBold),
                      ),
                      _LectureRowEntry(
                        :final first,
                        :final second,
                        :final isLastInSemester,
                      ) =>
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: isLastInSemester ? 8.0 : 0.0,
                          ),
                          child: _buildLectureRow(context, user, first, second),
                        ),
                    };
                  }, childCount: entries.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLectureRow(
    BuildContext context,
    User user,
    Lecture first,
    Lecture? second,
  ) {
    if (second == null) {
      return Row(
        children: <Widget>[
          Expanded(child: _buildLectureBlock(context, user, first)),
          Expanded(child: const SizedBox()),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(child: _buildLectureBlock(context, user, first)),
          Expanded(child: _buildLectureBlock(context, user, second)),
        ],
      ),
    );
  }

  Widget _buildLectureBlock(BuildContext context, User user, Lecture lecture) {
    return LectureSimpleBlock(
      lecture: lecture,
      hasReview: user.reviews.any((review) => review.lecture.id == lecture.id),
      onTap: () {
        context.read<LectureDetailModel>().loadLecture(lecture.id, false);
        OTLNavigator.push(context, LectureDetailPage());
      },
    );
  }
}

sealed class _ReviewListEntry {
  const _ReviewListEntry();
}

class _SemesterHeaderEntry extends _ReviewListEntry {
  const _SemesterHeaderEntry(this.semester);

  final Semester semester;
}

class _LectureRowEntry extends _ReviewListEntry {
  const _LectureRowEntry({
    required this.first,
    required this.second,
    required this.isLastInSemester,
  });

  final Lecture first;
  final Lecture? second;
  final bool isLastInSemester;
}
