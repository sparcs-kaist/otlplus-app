import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/extensions/semester.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/widgets/dropdown.dart';
import 'package:provider/provider.dart';

class HallOfFameControl extends StatefulWidget {
  const HallOfFameControl({
    required this.selectedSemester,
    required this.onChanged,
    super.key,
  });

  final Semester? selectedSemester;
  final ValueChanged<Semester?> onChanged;

  @override
  State<HallOfFameControl> createState() => _HallOfFameControlState();
}

class _HallOfFameControlState extends State<HallOfFameControl> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final targetSemesters = context
        .watch<InfoModel>()
        .semesters
        .where(
          (semester) =>
              semester.year >= 2013 &&
              (semester.gradePosting == null ||
                  DateTime.now().isAfter(
                    semester.gradePosting!.add(const Duration(days: 30)),
                  )),
        )
        .toList();

    return Dropdown<Semester?>(
      customButton: Container(
        height: 34,
        padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        decoration: BoxDecoration(
          color: OTLColor.grayF,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Text(
              widget.selectedSemester == null
                  ? 'common.all'.tr()
                  : widget.selectedSemester!.title,
              style: bodyBold.copyWith(color: OTLColor.pinksMain),
            ),
            const SizedBox(width: 2),
            Icon(
              _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: OTLColor.pinksMain,
            ),
          ],
        ),
      ),
      items: [
        ItemData(
          value: null,
          text: 'common.all'.tr(),
          icon: widget.selectedSemester == null ? Icons.check : null,
        ),
        ...List.generate(
          targetSemesters.length,
          (index) => ItemData(
            value: targetSemesters[index],
            text: targetSemesters[index].title,
            icon: widget.selectedSemester == targetSemesters[index]
                ? Icons.check
                : null,
          ),
        ).reversed,
      ],
      hasScrollbar: true,
      onChanged: widget.onChanged,
      onMenuStateChange: (isOpen) => setState(() => _isOpen = isOpen),
    );
  }
}
