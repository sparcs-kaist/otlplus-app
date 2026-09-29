import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/extensions/semester.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:otlplus/widgets/semester_picker.dart';
import 'package:otlplus/widgets/timetable_mode_control.dart';
import 'package:provider/provider.dart';

class TimetableLayout extends StatelessWidget {
  const TimetableLayout({super.key, required this.body});
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TimetableModel>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = TextPainter(
          text: TextSpan(
            text: model.selectedSemester.title,
            style: displayBold.copyWith(height: 1.448),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        // Picker: two 32px arrows + 16px title padding. Mode control: 164px.
        final stacked = title.width + 80 + 16 + 164 > constraints.maxWidth;
        final pickerHeight = math.max(32.0, title.height + 16);
        title.dispose();
        final picker = SemesterPicker(
          onSemesterChanged: () {
            model.setTempLecture(null);
            context.read<LectureSearchModel>().lectureClear();
          },
        );
        final modes = TimetableModeControl(
          selectedMode: model.selectedMode,
          onTap: model.setMode,
        );
        return OTLLayout(
          toolbarHeight: stacked
              ? pickerHeight + 48
              : math.max(kToolbarHeight, pickerHeight),
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: stacked
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [picker, const SizedBox(height: 4), modes],
                  )
                : picker,
          ),
          trailing: stacked ? null : modes,
          body: body,
        );
      },
    );
  }
}
