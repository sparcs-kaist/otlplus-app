import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/theme/context_ext.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/widgets/dropdown.dart';
import 'package:provider/provider.dart';

class HallOfFameControl extends StatefulWidget {
  HallOfFameControl({Key? key}) : super(key: key);

  @override
  State<HallOfFameControl> createState() => _HallOfFameControlState();
}

class _HallOfFameControlState extends State<HallOfFameControl> {
  late List<Semester> _targetSemesters;
  late Semester? _currentSemester;
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    _targetSemesters = context
        .watch<InfoModel>()
        .semesters
        .where(
          (s) =>
              s.year >= 2013 &&
              (s.gradePosting == null ||
                  DateTime.now().isAfter(
                    s.gradePosting!.add(Duration(days: 30)),
                  )),
        )
        .toList();
    _currentSemester = context.read<HallOfFameModel>().semeseter;

    return Dropdown<Semester?>(
      customButton: Container(
        height: 34,
        padding: EdgeInsets.fromLTRB(16, 0, 8, 0),
        decoration: BoxDecoration(
          color: context.colors.backgroundSectionDefault,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Text(
              _currentSemester == null
                  ? "common.all".tr()
                  : "${_currentSemester?.year} ${_currentSemester?.semester == 1 ? 'semester.spring'.tr() : 'semester.fall'.tr()}",
              style: context.texts.normalBold.copyWith(
                color: context.colors.highlightDefault,
              ),
            ),
            const SizedBox(width: 2.0),
            Icon(
              _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: context.colors.highlightDefault,
            ),
          ],
        ),
      ),
      items: [
        ItemData(
          value: null,
          text: 'common.all'.tr(),
          icon: _currentSemester == null ? Icons.check : null,
        ),
        ...List.generate(
          _targetSemesters.length,
          (index) => ItemData(
            value: _targetSemesters[index],
            text:
                "${_targetSemesters[index].year} ${_targetSemesters[index].semester == 1 ? 'semester.spring'.tr() : 'semester.fall'.tr()}",
            icon: _currentSemester == _targetSemesters[index]
                ? Icons.check
                : null,
          ),
        ).reversed,
      ],
      hasScrollbar: true,
      onChanged: (value) {
        setState(() {
          context.read<HallOfFameModel>().setSemester(value);
          context.read<HallOfFameModel>().clear();
        });
      },
      onMenuStateChange: (isOpen) => setState(() => _isOpen = isOpen),
    );
  }
}
