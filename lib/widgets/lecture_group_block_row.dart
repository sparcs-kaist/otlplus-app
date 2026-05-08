import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/theme/context_ext.dart';
import 'package:otlplus/extensions/lecture.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:provider/provider.dart';

import '../providers/timetable_model.dart';

class LectureGroupBlockRow extends StatefulWidget {
  const LectureGroupBlockRow({
    Key? key,
    required this.lecture,
    this.onLongPress,
  }) : super(key: key);

  final Lecture lecture;
  final VoidCallback? onLongPress;

  @override
  State<LectureGroupBlockRow> createState() => _LectureGroupBlockRowState();
}

class _LectureGroupBlockRowState extends State<LectureGroupBlockRow> {
  RegExp exp = new RegExp(r"[^A-Z]");
  @override
  Widget build(BuildContext context) {
    final isEn = EasyLocalization.of(context)?.currentLocale == Locale('en');
    final alreadyAdded = context.select<TimetableModel, bool>(
      (model) => model.currentTimetable.lectures.any(
        (lec) =>
            lec.oldCode == widget.lecture.oldCode &&
            widget.lecture.classTitle == lec.classTitle,
      ),
    );
    bool selected =
        context.watch<TimetableModel>().tempLecture == widget.lecture;
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: GestureDetector(
          onTap: () {
            if (context.read<TimetableModel>().tempLecture != widget.lecture) {
              context.read<TimetableModel>().setTempLecture(widget.lecture);
            } else {
              context.read<TimetableModel>().setTempLecture(null);
            }
          },
          onLongPress: widget.onLongPress,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? context.colors.lineDark : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
                    child: Wrap(
                      children: [
                        Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(
                                text: widget.lecture.classTitle,
                                style: context.texts.normalBold,
                              ),
                              WidgetSpan(child: const SizedBox(width: 8)),
                              WidgetSpan(
                                child: Text(
                                  isEn
                                      ? widget.lecture.professorsStrShortEn
                                      : widget.lecture.professorsStrShort,
                                  style: context.texts.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: SizedBox(
                    width: 50,
                    child: Visibility(
                      visible: selected,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconTextButton(
                            icon: 'assets/icons/info.svg',
                            iconSize: 20.0,
                            onTap: widget.onLongPress,
                            color: context.colors.textDark,
                          ),
                          SizedBox(width: 6.0),
                          IconTextButton(
                            onTap: () {
                              if (alreadyAdded) {
                                _removeLecture(widget.lecture);
                              } else {
                                _addLecture(widget.lecture);
                              }
                            },
                            icon: alreadyAdded
                                ? Icons.remove
                                : 'assets/icons/add.svg',
                            iconSize: 24,
                            color: alreadyAdded
                                ? context.colors.highlightDefault
                                : context.colors.textDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addLecture(Lecture lec) async {
    final isKo = context.locale == Locale('ko');
    final lectureTitle = isKo ? lec.title : lec.titleEn;

    bool result = await context.read<TimetableModel>().addLecture(
      lecture: lec,
      noOverlap: () async {
        bool result = false;

        await OTLNavigator.pushDialog(
          context: context,
          builder: (_) => OTLDialog(
            type: OTLDialogType.addLecture,
            namedArgs: {'lecture': lectureTitle},
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
            type: OTLDialogType.addOverlappingLecture,
            namedArgs: {
              'lectures': lectures
                  .map(
                    (lecture) => "'${isKo ? lecture.title : lecture.titleEn}'",
                  )
                  .join(', '),
              'lecture': lectureTitle,
            },
            onTapPos: () => result = true,
          ),
        );

        return result;
      },
    );
    if (result) {
      context.read<TimetableModel>().setTempLecture(null);
    }
  }

  Future<void> _removeLecture(Lecture lec) async {
    await OTLNavigator.pushDialog(
      context: context,
      builder: (_) => OTLDialog(
        type: OTLDialogType.deleteLecture,
        namedArgs: {
          'lecture': context.locale == Locale('ko') ? lec.title : lec.titleEn,
        },
        onTapPos: () =>
            context.read<TimetableModel>().removeLecture(lecture: lec),
      ),
    );
    context.read<TimetableModel>().setTempLecture(null);
  }
}
