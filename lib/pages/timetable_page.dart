import 'package:flutter/material.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/pages/lecture_search_page.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/widgets/lecture_search.dart';
import 'package:otlplus/widgets/map_view.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:otlplus/widgets/semester_picker.dart';
import 'package:otlplus/widgets/timetable_mode_control.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/widgets/timetable.dart';
import 'package:otlplus/widgets/timetable_block.dart';
import 'package:otlplus/widgets/timetable_summary.dart';
import 'package:otlplus/widgets/timetable_tabs.dart';
import 'package:easy_localization/easy_localization.dart';

class TimetablePage extends StatefulWidget {
  static String route = 'timetable_page';

  @override
  _TimetablePageState createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final _selectedKey = GlobalKey();
  final _paintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final timetableModel = context.watch<TimetableModel>();

    if (timetableModel.isLoaded) {
      return KeyedSubtree(
        key: const Key('timetable_loaded'),
        child: _buildBody(context),
      );
    }
    if (timetableModel.loadFailed) {
      return Center(
        child: Column(
          key: const Key('timetable_error'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('error.load_timetable'.tr()),
            TextButton(
              onPressed: timetableModel.retryLoad,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }
    return Center(child: const CircularProgressIndicator());
  }

  Widget _buildBody(BuildContext context) {
    final lectures = context.select<TimetableModel, List<Lecture>>(
      (model) => model.currentTimetable.lectures,
    );
    final mode = context.select<TimetableModel, TimetableViewMode>(
      (model) => model.selectedMode,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedKey.currentContext != null)
        Scrollable.ensureVisible(_selectedKey.currentContext!);
    });

    return OTLLayout(
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: SemesterPicker(
          onSemesterChanged: () {
            context.read<TimetableModel>().setTempLecture(null);
            context.read<LectureSearchModel>().lectureClear();
          },
        ),
      ),
      trailing: TimetableModeControl(
        selectedMode: context.watch<TimetableModel>().selectedMode,
        onTap: (mode) => context.read<TimetableModel>().setMode(mode),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ColoredBox(
              color: OTLColor.grayF,
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            color: OTLColor.pinksLight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: OTLColor.grayF,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                ),
                              ),
                              child: _buildTimetableTabs(context),
                            ),
                          ),
                        ),
                        if (mode == TimetableViewMode.classes)
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              OTLNavigator.push(
                                context,
                                LectureSearchPage(openKeyboard: false),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                18,
                                16,
                                18,
                              ),
                              child: Icon(
                                Icons.search,
                                size: 24,
                                color: OTLColor.pinksMain,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    child: () {
                      switch (mode) {
                        case TimetableViewMode.classes:
                          return _buildTimetableMode(context, lectures, false);
                        case TimetableViewMode.exams:
                          return _buildTimetableMode(context, lectures, true);
                        case TimetableViewMode.map:
                          return MapView(lectures: lectures);
                      }
                    }(),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: context.watch<LectureSearchModel>().resultOpened,
            child: Expanded(
              child: LectureSearch(
                onClosed: () async {
                  context.read<LectureSearchModel>().resetLectureFilter();
                  context.read<TimetableModel>().setTempLecture(null);
                  return true;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableMode(
    BuildContext context,
    List<Lecture> lectures,
    bool isExamTime,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: RepaintBoundary(
              key: _paintKey,
              child: Container(
                color: OTLColor.grayF,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTimetable(context, lectures, isExamTime),
              ),
            ),
          ),
        ),
        if (!isExamTime) TimetableSummary(),
      ],
    );
  }

  Timetable _buildTimetable(
    BuildContext context,
    List<Lecture> lectures,
    bool isExamTime,
  ) {
    bool isFirst = true;
    final tempLecture = context.select<TimetableModel, Lecture?>(
      (model) => model.tempLecture,
    );

    return Timetable(
      lectures: (tempLecture == null) ? lectures : [...lectures, tempLecture],
      isExamTime: isExamTime,
      builder: (lecture, classTimeIndex, blockHeight) {
        final isSelected = tempLecture == lecture;
        Key? key;

        if (isSelected && isFirst) {
          key = _selectedKey;
          isFirst = false;
        }

        return TimetableBlock(
          key: key,
          lecture: lecture,
          classTimeIndex: classTimeIndex,
          height: blockHeight,
          isTemp: isSelected,
          isExamTime: isExamTime,
          onTap: () {
            context.read<LectureDetailModel>().loadLecture(lecture.id, true);
            OTLNavigator.push(context, LectureDetailPage());
          },
          onLongPress:
              isSelected || context.read<TimetableModel>().isMyTimetable
              ? null
              : () {
                  OTLNavigator.pushDialog(
                    context: context,
                    builder: (_) => OTLDialog(
                      type: OTLDialogType.deleteLecture,
                      namedArgs: {
                        'lecture': context.locale == Locale('ko')
                            ? lecture.title
                            : lecture.titleEn,
                      },
                      onTapPos: () => context
                          .read<TimetableModel>()
                          .removeLecture(lecture: lecture),
                    ),
                  );
                },
        );
      },
    );
  }

  void _handleTimetableTabAction(
    BuildContext context,
    TimetableModel timetableModel,
    TimetableTabAction action,
    int index,
  ) {
    switch (action) {
      case TimetableTabAction.copy:
        timetableModel.createTimetable(
          lectures: timetableModel.currentTimetable.lectures,
        );
        return;
      case TimetableTabAction.exportImage:
        timetableModel.shareTimetable(
          ShareType.image,
          context.locale.languageCode,
        );
        return;
      case TimetableTabAction.exportIcal:
        timetableModel.shareTimetable(
          ShareType.ical,
          context.locale.languageCode,
        );
        return;
      case TimetableTabAction.delete:
        if (timetableModel.isMyTimetableIndex(index)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            OTLNavigator.pushDialog(
              context: context,
              builder: (_) => OTLDialog(
                type: OTLDialogType.accountDeleted,
                namedArgs: {
                  'timetable': 'timetable.tab'.tr(
                    args: [timetableModel.selectedIndex.toString()],
                  ),
                },
                onTapPos: () {},
              ),
            );
          });
        } else if (timetableModel.timetables.length <= 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            OTLNavigator.pushDialog(
              context: context,
              builder: (_) => OTLDialog(
                type: OTLDialogType.disabledDeleteLastTab,
                namedArgs: {
                  'timetable': 'timetable.tab'.tr(
                    args: [timetableModel.selectedIndex.toString()],
                  ),
                },
              ),
            );
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            OTLNavigator.pushDialog(
              context: context,
              builder: (_) => OTLDialog(
                type: OTLDialogType.deleteTab,
                namedArgs: {
                  'timetable': 'timetable.tab'.tr(
                    args: [timetableModel.selectedIndex.toString()],
                  ),
                },
                onTapPos: () =>
                    context.read<TimetableModel>().deleteTimetable(),
              ),
            );
          });
        }
        return;
    }
  }

  TimetableTabs _buildTimetableTabs(BuildContext context) {
    final timetableModel = context.watch<TimetableModel>();

    return TimetableTabs(
      index: timetableModel.selectedIndex,
      length: timetableModel.timetables.length,
      onTap: (i) {
        final timetableModel = context.read<TimetableModel>();

        if (i == timetableModel.timetables.length) {
          timetableModel.createTimetable();
        } else {
          timetableModel.setIndex(i);
        }
      },
      onAction: (action, index) =>
          _handleTimetableTabAction(context, timetableModel, action, index),
    );
  }
}
