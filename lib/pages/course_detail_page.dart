import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/extensions/course.dart';
import 'package:otlplus/extensions/lecture.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/professor.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/widgets/custom_header_delegate.dart';
import 'package:otlplus/widgets/lecture_group_simple_block.dart';
import 'package:otlplus/widgets/review_block.dart';
import 'package:otlplus/widgets/review_write_block.dart';
import 'package:otlplus/extensions/locale.dart';

class CourseDetailPage extends StatelessWidget {
  CourseDetailPage({Key? key}) : super(key: key);
  static String route = 'course_detail_page';

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final CourseDetailModel courseDetailModel = context
        .watch<CourseDetailModel>();
    final isEn = context.isEn;

    return OTLScaffold(
      child: OTLLayout(
        middle: Text(
          courseDetailModel.hasData
              ? (isEn
                    ? courseDetailModel.course.titleEn
                    : courseDetailModel.course.title)
              : '',
          style: titleBold,
        ),
        body: Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          child:
              context.select<CourseDetailModel, bool>((model) => model.hasData)
              ? _buildBody(context)
              : courseDetailModel.loadFailed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEn
                            ? 'Unable to load course details.'
                            : '과목 정보를 불러오지 못했습니다.',
                      ),
                      TextButton(
                        onPressed: courseDetailModel.retryLoad,
                        child: Text(isEn ? 'Retry' : '다시 시도'),
                      ),
                    ],
                  ),
                )
              : Center(child: const CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final course = context.select<CourseDetailModel, Course>(
      (model) => model.course,
    );

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: _buildScrollView(context, course),
    );
  }

  CustomScrollView _buildScrollView(BuildContext context, Course course) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate([
            _buildAttribute(context, course),
            _buildScores(context, course),
            _buildDivider(),
            _buildProfessors(context, course),
            _buildDivider(),
            const SizedBox(height: 8.0),
            Text("dictionary.course_history".tr(), style: bodyBold),
            _buildHistory(context),
            _buildDivider(),
            const SizedBox(height: 8.0),
          ]),
        ),
        _buildReviewHeader(),
        _buildReviews(context, course),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(color: OTLColor.gray0.withValues(alpha: .25));
  }

  SliverPersistentHeader _buildReviewHeader() {
    final headerKey = GlobalKey();
    return SliverPersistentHeader(
      pinned: true,
      delegate: CustomHeaderDelegate(
        height: 24.0,
        padding: const EdgeInsets.only(bottom: 4.0),
        builder: (shrinkOffset) => IconTextButton(
          direction: ButtonDirection.rowReversed,
          padding: EdgeInsets.zero,
          onTap: () async {
            if (shrinkOffset > 0) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              await Scrollable.ensureVisible(
                headerKey.currentContext!,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _scrollController.jumpTo(_scrollController.offset + 2);
            }
          },
          key: headerKey,
          text: "dictionary.reviews".tr(),
          textStyle: bodyBold,
          icon: (shrinkOffset > 0)
              ? Icons.keyboard_arrow_up
              : Icons.keyboard_arrow_down,
        ),
      ),
    );
  }

  ChoiceChip _buildChoiceChip(
    BuildContext context,
    String selectedFilter,
    Professor? professor,
  ) {
    final isEn = context.isEn;

    return ChoiceChip(
      selectedColor: OTLColor.pinksSub,
      backgroundColor: OTLColor.grayE,
      label: Text(
        professor == null
            ? "common.all".tr()
            : (isEn
                  ? (professor.nameEn == '' ? professor.name : professor.nameEn)
                  : professor.name),
        style: labelRegular,
      ),
      selected: (professor == null
          ? selectedFilter == "ALL"
          : selectedFilter == professor.professorId.toString()),
      onSelected: (isSelected) {
        context.read<CourseDetailModel>().setFilter(
          (professor != null && isSelected)
              ? professor.professorId.toString()
              : "ALL",
        );
      },
    );
  }

  Widget _buildProfessors(BuildContext context, Course course) {
    final courseDetailModel = context.watch<CourseDetailModel>();

    return Row(
      children: <Widget>[
        Text("dictionary.professors".tr(), style: bodyBold),
        const SizedBox(width: 8.0),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: _buildChoiceChip(
                    context,
                    courseDetailModel.selectedFilter,
                    null,
                  ),
                ),
                ...courseDetailModel.professors
                    .toSet()
                    .map(
                      (professor) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: _buildChoiceChip(
                          context,
                          courseDetailModel.selectedFilter,
                          professor,
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScores(BuildContext context, Course course) {
    final lecture = context.select<CourseDetailModel, Lecture?>(
      (model) => model.selectedLecture,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _buildStatus(
          "review.grade".tr(),
          (lecture == null) ? course.gradeLetter : lecture.gradeLetter,
        ),
        _buildStatus(
          "review.load".tr(),
          (lecture == null) ? course.loadLetter : lecture.loadLetter,
        ),
        _buildStatus(
          "review.speech".tr(),
          (lecture == null) ? course.speechLetter : lecture.speechLetter,
        ),
      ],
    );
  }

  Column _buildAttribute(BuildContext context, Course course) {
    final isEn = context.isEn;

    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("dictionary.code".tr(), style: bodyBold),
            const SizedBox(width: 8.0),
            Expanded(child: Text(course.oldCode, style: bodyRegular)),
          ],
        ),
        const SizedBox(height: 4.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("dictionary.type".tr(), style: bodyBold),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                "${isEn ? course.department?.nameEn : course.department?.name}, ${isEn ? course.typeEn : course.type}",
                style: bodyRegular,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("dictionary.description".tr(), style: bodyBold),
            const SizedBox(width: 8.0),
            Expanded(child: Text(course.summary, style: bodyRegular)),
          ],
        ),
        const SizedBox(height: 4.0),
      ],
    );
  }

  Widget _buildHistory(BuildContext context) {
    final _scrollController = ScrollController();
    final years = context.select<InfoModel, Set<int>>((model) => model.years);
    final courseDetailModel = context.watch<CourseDetailModel>();
    final isEn = context.isEn;

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        reverse: true,
        child: Column(
          children: <Widget>[
            for (final season in [Season.spring, Season.summer])
              _buildHistoryRow(
                context,
                courseDetailModel.lectures,
                years,
                season,
                courseDetailModel.selectedFilter,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: years
                    .map(
                      (year) => Container(
                        width: isEn ? 150.0 : 100.0,
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          year.toString(),
                          textAlign: TextAlign.center,
                          style: bodyBold,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            for (final season in [Season.fall, Season.winter])
              _buildHistoryRow(
                context,
                courseDetailModel.lectures,
                years,
                season,
                courseDetailModel.selectedFilter,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(
    BuildContext context,
    List<Lecture> lectures,
    Set<int> years,
    Season season,
    String selectedFilter,
  ) {
    final isEn = context.isEn;

    return IntrinsicHeight(
      child: Row(
        children: years.map((year) {
          final filteredLectures = lectures
              .where(
                (lecture) =>
                    lecture.year == year &&
                    Season.fromCode(lecture.semester) == season,
              )
              .toList();
          if (filteredLectures.length == 0)
            return Container(
              width: isEn ? 150.0 : 100.0,
              margin: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Text(
                "dictionary.not_offered".tr(),
                textAlign: TextAlign.center,
                style: bodyRegular.copyWith(color: OTLColor.grayA),
              ),
            );
          return LectureGroupSimpleBlock(
            lectures: filteredLectures,
            semester: season.code,
            filter: selectedFilter,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviews(BuildContext context, Course course) {
    final user = context.watch<InfoModel>().userOrNull;
    final selectedFilter = context.select<CourseDetailModel, String>(
      (model) => model.selectedFilter,
    );

    return SliverList(
      delegate: SliverChildListDelegate([
        if (user != null)
          ...user.reviewWritableLectures
              .where(
                (lecture) =>
                    lecture.course == course.id &&
                    (selectedFilter == "ALL" ||
                        lecture.professors.any(
                          (professor) =>
                              professor.professorId.toString() ==
                              selectedFilter,
                        )),
              )
              .map((lecture) {
                Review? existingReview;
                try {
                  existingReview = user.reviews.firstWhere(
                    (review) => review.lecture.id == lecture.id,
                    orElse: null,
                  );
                } catch (_) {}
                return ReviewWriteBlock(
                  lecture: lecture,
                  existingReview: existingReview,
                  isSimple: false,
                  onUploaded: () async {
                    final infoModel = context.read<InfoModel>();
                    final detailModel = context.read<CourseDetailModel>();
                    await Future.wait<void>(<Future<void>>[
                      infoModel.reload(),
                      detailModel.loadCourse(course.id),
                    ]);
                  },
                );
              })
              .toList(),
        ...context.select<CourseDetailModel, List<Widget>>((model) {
          final reviews = model.reviews;
          if (reviews.isEmpty) {
            return [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "common.no_result".tr(),
                    style: labelRegular.copyWith(color: OTLColor.grayA),
                  ),
                ),
              ),
            ];
          }
          return reviews.map((review) => ReviewBlock(review: review)).toList();
        }),
      ]),
    );
  }

  Widget _buildStatus(String title, String content) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: <Widget>[
          Text(content, style: titleRegular),
          Text(title, style: labelRegular),
        ],
      ),
    );
  }
}
