import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/extensions/semester.dart';
import 'package:otlplus/providers/timetable_model.dart';

class SemesterPicker extends StatefulWidget {
  final bool isExamTime;
  final Function() onSemesterChanged;

  SemesterPicker({this.isExamTime = false, required this.onSemesterChanged});

  @override
  _SemesterPickerState createState() => _SemesterPickerState();
}

class _SemesterPickerState extends State<SemesterPicker> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildLeftButton(theme),
        _buildTitle(context),
        _buildRightButton(theme),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        context.watch<TimetableModel>().selectedSemester.title,
        style: displayBold.copyWith(height: 1.448),
      ),
    );
  }

  Widget _buildLeftButton(ThemeData theme) {
    final canGoPreviousSemester = context.select<TimetableModel, bool>(
      (m) => m.canGoPreviousSemester,
    );
    return IconTextButton(
      onTap: canGoPreviousSemester
          ? () {
              context.read<TimetableModel>().goPreviousSemester();
              widget.onSemesterChanged();
            }
          : null,
      icon: Icons.navigate_before_outlined,
      iconSize: 24,
      color: canGoPreviousSemester ? OTLColor.gray0 : OTLColor.grayA,
      padding: const EdgeInsets.all(4.0),
      tapEffect: canGoPreviousSemester
          ? ButtonTapEffect.lighten
          : ButtonTapEffect.none,
    );
  }

  Widget _buildRightButton(ThemeData theme) {
    final canGoNextSemester = context.select<TimetableModel, bool>(
      (m) => m.canGoNextSemester,
    );
    return IconTextButton(
      onTap: canGoNextSemester
          ? () {
              context.read<TimetableModel>().goNextSemester();
              widget.onSemesterChanged();
            }
          : null,
      icon: Icons.navigate_next_outlined,
      iconSize: 24,
      color: canGoNextSemester ? OTLColor.gray0 : OTLColor.grayA,
      padding: const EdgeInsets.all(4.0),
      tapEffect: canGoNextSemester
          ? ButtonTapEffect.lighten
          : ButtonTapEffect.none,
    );
  }
}
