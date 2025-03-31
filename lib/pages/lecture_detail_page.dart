import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/extensions/semester.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/extensions/lecture.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/widgets/custom_header_delegate.dart';
import 'package:otlplus/widgets/review_block.dart';
import 'package:otlplus/widgets/review_write_block.dart';

class LectureDetailPage extends StatelessWidget {
  LectureDetailPage({Key? key, this.fromCourseDetailPage = false})
      : super(key: key);

  static String route = 'lecture_detail_page';
  final bool fromCourseDetailPage;
  final _scrollController = ScrollController();

  String _getSyllabusUrl(Lecture lecture) {
    final payload = {
      "syy": lecture.year.toString(),
      "smtDivCd": lecture.semester.toString(),
      "subjtCd": lecture.oldCode,
    };

    final payloadJson = jsonEncode(payload);
    final payloadBase64 = base64Encode(utf8.encode(payloadJson));

    return Uri.https("erp.kaist.ac.kr", "/com/lgin/SsoCtr/initExtPageWork.do", {
      "link": "estblSubjt",
      "params": payloadBase64,
    }).toString();
  }

  @override
  Widget build(BuildContext context) {
    final LectureDetailModel lectureDetailModel =
        context.watch<LectureDetailModel>();
    final isEn = EasyLocalization.of(context)?.currentLocale == Locale('en');

    return OTLScaffold(
      child: OTLLayout(
        middle: Text(
            lectureDetailModel.hasData
                ? (isEn
                    ? lectureDetailModel.lecture.titleEn
                    : lectureDetailModel.lecture.title)
                : '',
            style: titleBold),
        body: Card(
          shape: const RoundedRectangleBorder(),
          child:
              context.select<LectureDetailModel, bool>((model) => model.hasData)
                  ? _buildBody(context)
                  : Center(
                      child: const CircularProgressIndicator(),
                    ),
        ),
        trailing: (context.select<LectureDetailModel, bool>(
                    (model) => model.hasData) &&
                context.select<LectureDetailModel, bool>(
                    (model) => model.isUpdateEnabled) &&
                context.read<TimetableModel>().selectedIndex != 0)
            ? _buildUpdateButton(context)
            : null,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final lecture =
        context.select<LectureDetailModel, Lecture>((model) => model.lecture);

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: <Widget>[
          _buildButtons(context, lecture),
          const SizedBox(height: 8.0),
          Expanded(child: _buildScrollView(context, lecture)),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(BuildContext context) {
    final lecture =
        context.select<LectureDetailModel, Lecture>((model) => model.lecture);
    final isAdded = context.select<TimetableModel, bool>(
        (model) => model.currentTimetable.lectures.contains(lecture));

    return IconTextButton(
      padding: const EdgeInsets.all(16),
      onTap: () {
        final timetableModel = context.read<TimetableModel>();
        final isKo = context.locale == Locale('ko');
        final lectureTitle = isKo ? lecture.title : lecture.titleEn;
        final timetable =
            '${timetableModel.selectedSemester.title} ${'timetable.tab'.tr(
          args: [timetableModel.selectedIndex.toString()],
        )}';

        if (isAdded) {
          OTLNavigator.pushDialog(
            context: context,
            builder: (_) => OTLDialog(
              type: OTLDialogType.deleteLectureWithTab,
              namedArgs: {'lecture': lectureTitle, 'timetable': timetable},
              onTapPos: () => timetableModel.removeLecture(lecture: lecture),
            ),
          );
        } else {
          timetableModel.addLecture(
            lecture: lecture,
            noOverlap: () async {
              bool result = false;

              await OTLNavigator.pushDialog(
                context: context,
                builder: (_) => OTLDialog(
                  type: OTLDialogType.addLectureWithTab,
                  namedArgs: {'lecture': lectureTitle, 'timetable': timetable},
                  onTapPos: () => result = true,
                ),
              );

              return result;
            },
            onOverlap: (lectures) async {
              bool result = false;

              await OTLNavigator.pushDialog(
                context: context,
                builder: (_) => OTLDialog(
                  type: OTLDialogType.addOverlappingLectureWithTab,
                  namedArgs: {
                    'lectures': lectures
                        .map((lecture) =>
                            "'${isKo ? lecture.title : lecture.titleEn}'")
                        .join(', '),
                    'lecture': lectureTitle,
                    'timetable': timetable
                  },
                  onTapPos: () => result = true,
                ),
              );

              return result;
            },
          );
        }
      },
      icon: isAdded
          ? Icons.remove_circle_outline_rounded
          : Icons.add_circle_outline_rounded,
    );
  }

  Widget _buildButtons(BuildContext context, Lecture lecture) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: IconTextButton(
            onTap: () {
              if (fromCourseDetailPage) {
                OTLNavigator.pop(context);
              } else {
                context.read<CourseDetailModel>().loadCourse(lecture.course);
                OTLNavigator.push(context, CourseDetailPage());
              }
            },
            text: "dictionary.dictionary".tr(),
            textStyle: bodyRegular.copyWith(color: OTLColor.pinksMain),
          ),
        ),
        IconTextButton(
          onTap: () => FlutterWebBrowser.openWebPage(
            url: _getSyllabusUrl(lecture),
            customTabsOptions: CustomTabsOptions(
              colorScheme: CustomTabsColorScheme.light,
              defaultColorSchemeParams: CustomTabsColorSchemeParams(
                  toolbarColor: OTLColor.pinksLight),
              shareState: CustomTabsShareState.on,
              instantAppsEnabled: true,
              showTitle: true,
              urlBarHidingEnabled: true,
            ),
            safariVCOptions: SafariViewControllerOptions(
              barCollapsingEnabled: true,
              dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
              modalPresentationCapturesStatusBarAppearance: true,
            ),
          ),
          text: "dictionary.syllabus".tr(),
          textStyle: bodyRegular.copyWith(color: OTLColor.pinksMain),
        ),
      ],
    );
  }

  CustomScrollView _buildScrollView(BuildContext context, Lecture lecture) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate([
            _buildAttributes(context, lecture),
            _buildScores(lecture),
            const SizedBox(height: 16.0),
          ]),
        ),
        _buildReviewHeader(),
        _buildReviews(context, lecture),
      ],
    );
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
                _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
              } else {
                await Scrollable.ensureVisible(headerKey.currentContext!,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut);
                _scrollController.jumpTo(_scrollController.offset + 2);
              }
            },
            key: headerKey,
            text: "dictionary.reviews".tr(),
            textStyle: bodyBold,
            icon: (shrinkOffset > 0)
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down),
      ),
    );
  }

  SliverList _buildReviews(BuildContext context, Lecture lecture) {
    final user = context.watch<InfoModel>().user;
    Review? existingReview;
    try {
      existingReview =
          user.reviews.firstWhere((review) => review.lecture.id == lecture.id);
    } on StateError {}

    return SliverList(
      delegate: SliverChildListDelegate([
        if (user.reviewWritableLectures.contains(lecture))
          ReviewWriteBlock(
            lecture: lecture,
            existingReview: existingReview,
            isSimple: true,
            onUploaded: (review) {
              context.read<InfoModel>().getInfo();
              context.read<LectureDetailModel>().updateLectureReviews(review);
            },
          ),
        ...context.select<LectureDetailModel, List<Widget>>((model) {
          if (model.reviews.length == 0) {
            return [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "common.no_result".tr(),
                    style: labelRegular.copyWith(color: OTLColor.grayA),
                  ),
                ),
              )
            ];
          } else {
            return model.reviews
                .map((review) => ReviewBlock(
                      review: review,
                    ))
                .toList();
          }
        }),
      ]),
    );
  }

  Widget _buildScores(Lecture lecture) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        children: <TableRow>[
          TableRow(
            children: <Widget>[
              _buildStatus(
                "dictionary.language".tr(),
                lecture.isEnglish ? "Eng" : "한",
              ),
              _buildStatus(
                  (lecture.credit > 0) ? "dictionary.credit".tr() : "AU",
                  (lecture.credit > 0)
                      ? lecture.credit.toString()
                      : lecture.creditAu.toString()),
              _buildStatus(
                "dictionary.competition".tr(),
                (lecture.limit == 0)
                    ? "0.0:1"
                    : "${(lecture.numPeople / lecture.limit).toStringAsFixed(1)}:1",
              ),
            ],
          ),
          TableRow(
            children: <Widget>[
              _buildStatus("review.grade".tr(), lecture.gradeLetter),
              _buildStatus("review.load".tr(), lecture.loadLetter),
              _buildStatus("review.speech".tr(), lecture.speechLetter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttribute(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: bodyBold),
          const SizedBox(width: 4.0),
          Expanded(child: Text(content, style: bodyRegular)),
        ],
      ),
    );
  }

  Widget _buildAttributes(BuildContext context, Lecture lecture) {
    final isEn = EasyLocalization.of(context)?.currentLocale == Locale('en');

    return Column(
      children: [
        _buildAttribute("dictionary.code".tr(), lecture.oldCode),
        _buildAttribute(
          "dictionary.type".tr(),
          isEn ? lecture.typeEn : lecture.type,
        ),
        _buildAttribute(
          "dictionary.department".tr(),
          isEn ? lecture.departmentNameEn : lecture.departmentName,
        ),
        _buildAttribute(
          "dictionary.professors".tr(),
          isEn ? lecture.professorsStrShortEn : lecture.professorsStrShort,
        ),
        _buildAttribute(
            "dictionary.classroom".tr(),
            lecture.classtimes
                .map((classtime) =>
                    isEn ? classtime.classroomEn : classtime.classroom)
                .toSet()
                .join(", ")),
        _buildAttribute(
          "dictionary.limit".tr(),
          lecture.limit.toString(),
        ),
        _buildAttribute(
          "dictionary.exam".tr(),
          (lecture.examtimes.length == 0)
              ? "common.no_info".tr()
              : lecture.examtimes
                  .map((examtime) => isEn ? examtime.strEn : examtime.str)
                  .toSet()
                  .join(", "),
        ),
      ],
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
