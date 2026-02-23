import 'package:flutter/material.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/pages/lecture_search_page.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/widgets/custom_block_dialog.dart';
import 'package:otlplus/widgets/custom_block_tile.dart';
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
    if (context.select<TimetableModel, bool>((model) => model.isLoaded))
      return _buildBody(context);
    return Center(child: const CircularProgressIndicator());
  }

  Widget _buildBody(BuildContext context) {
    final lectures = context.select<TimetableModel, List<Lecture>>(
      (model) => model.currentTimetable.lectures,
    );
    final customBlocks = context.select<TimetableModel, List<CustomBlock>>(
      (model) => model.currentTimetable.customBlocks,
    );
    final mode = context.select<TimetableModel, int>(
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
        dropdownIndex: context.watch<TimetableModel>().selectedMode,
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
                        if (mode == 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (context.read<TimetableModel>().selectedIndex != 0)
                                GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () {
                                    OTLNavigator.pushDialog(
                                      context: context,
                                      builder: (_) =>
                                          const AddCustomBlockDialog(),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      18,
                                      4,
                                      18,
                                    ),
                                    child: Icon(
                                      Icons.add_box_outlined,
                                      size: 24,
                                      color: OTLColor.pinksMain,
                                    ),
                                  ),
                                ),
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
                                    4,
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
                              ),
                            ],
                          )
                        else
                          const SizedBox(width: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    child: () {
                      switch (mode) {
                        case 0:
                        case 1:
                          return _buildTimetableMode(
                            context,
                            lectures,
                            customBlocks,
                            mode == 1,
                          );
                        default:
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
    List<CustomBlock> customBlocks,
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
                child: _buildTimetable(context, lectures, customBlocks, isExamTime),
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
    List<CustomBlock> customBlocks,
    bool isExamTime,
  ) {
    bool isFirst = true;
    final tempLecture = context.select<TimetableModel, Lecture?>(
      (model) => model.tempLecture,
    );

    return Timetable(
      lectures: (tempLecture == null) ? lectures : [...lectures, tempLecture],
      customBlocks: isExamTime ? null : customBlocks,
      isExamTime: isExamTime,
      customBlockBuilder: (block, blockHeight) {
        return CustomBlockTile(
          block: block,
          height: blockHeight,
          onLongPress: context.read<TimetableModel>().selectedIndex == 0
              ? null
              : () {
                  OTLNavigator.pushDialog(
                    context: context,
                    builder: (_) => DeleteCustomBlockDialog(block: block),
                  );
                },
        );
      },
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
              isSelected || context.read<TimetableModel>().selectedIndex == 0
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

  TimetableTabs _buildTimetableTabs(BuildContext context) {
    final timetableModel = context.watch<TimetableModel>();

    return TimetableTabs(
      index: timetableModel.selectedIndex,
      length: timetableModel.timetables.length,
      onTap: (i) {
        final timetableModel = context.read<TimetableModel>();

        if (i > 0 && i == timetableModel.timetables.length)
          timetableModel.createTimetable();
        else
          timetableModel.setIndex(i);
      },
      onCopyTap: () {
        final timetableModel = context.read<TimetableModel>();
        timetableModel.createTimetable(
          lectures: timetableModel.currentTimetable.lectures,
        );
        /*if (_isSearchOpened) return;
        setState(() {
          _isSearchOpened = true;
          _selectedLecture = null;
        });*/
      },
      onDeleteTap: (i) {
        if (i == 0) {
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
      },
      onExportTap: (type) {
        context.read<TimetableModel>().shareTimetable(
          type,
          context.locale.languageCode,
        );
      },
    );
  }
}
