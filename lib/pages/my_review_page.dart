import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/theme/context_ext.dart';
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

    return OTLScaffold(
      child: OTLLayout(
        middle: Text('user.my_review'.tr(), style: context.texts.bigBold),
        body: ColoredBox(
          color: context.colors.backgroundSectionDefault,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ...targetSemesters
                      .map(
                        (semester) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '${semester.year} ${["", "semester.spring".tr(), "semester.summer".tr(), "semester.fall".tr(), "semester.winter".tr()][semester.semester]}',
                                style: context.texts.smallBold,
                              ),
                            ),
                            ..._buildLectureBlocks(
                              context,
                              user,
                              user.reviewWritableLectures
                                  .where(
                                    (lecture) =>
                                        lecture.year == semester.year &&
                                        lecture.semester == semester.semester,
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 8.0),
                          ],
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLectureBlocks(
    BuildContext context,
    User user,
    List<Lecture> lectures,
  ) {
    final blocks = <Widget>[];
    for (int i = 0; i < lectures.length ~/ 2; i++) {
      blocks.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _buildLectureBlock(context, user, lectures[i * 2]),
              ),
              Expanded(
                child: _buildLectureBlock(context, user, lectures[i * 2 + 1]),
              ),
            ],
          ),
        ),
      );
    }

    if (blocks.length * 2 < lectures.length) {
      blocks.add(
        Row(
          children: <Widget>[
            Expanded(child: _buildLectureBlock(context, user, lectures.last)),
            Expanded(child: const SizedBox()),
          ],
        ),
      );
    }

    return blocks;
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
