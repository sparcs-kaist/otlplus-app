import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/widgets/dropdown.dart';

typedef TimetableTabActionCallback =
    void Function(TimetableTabAction action, int index);

class TimetableTabs extends StatefulWidget {
  final int index;
  final int length;
  final ValueChanged<int> onTap;
  final TimetableTabActionCallback onAction;

  TimetableTabs({
    this.index = 0,
    required this.length,
    required this.onTap,
    required this.onAction,
  });

  @override
  _TimetableTabsState createState() => _TimetableTabsState();
}

class _TimetableTabsState extends State<TimetableTabs> {
  int _index = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _index = widget.index;

    return Container(
      height: 28,
      padding: const EdgeInsets.only(left: 16.0),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.length + 1,
        itemBuilder: (context, i) => _buildTab(i, context),
      ),
    );
  }

  Widget _buildTab(int i, BuildContext context) {
    if (i == widget.length) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _index = i;
            widget.onTap(i);
          });
        },
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: OTLColor.pinksLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.add, size: 16),
        ),
      );
    }

    Text text = Text(
      i == 0
          ? 'timetable.my_tab'.tr()
          : 'timetable.tab'.tr(args: [i.toString()]),
      style: bodyBold.copyWith(
        color: i == _index ? OTLColor.grayF : OTLColor.gray0,
      ),
      textAlign: TextAlign.center,
    );

    if (i == _index) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Dropdown<TimetableTabAction>(
          customButton: Container(
            height: 28,
            padding: EdgeInsets.fromLTRB(12, 0, 8, 0),
            decoration: BoxDecoration(
              color: OTLColor.pinksMain,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                text,
                const SizedBox(width: 6),
                Icon(Icons.more_vert, color: OTLColor.grayF, size: 16),
              ],
            ),
          ),
          items: [
            ItemData(
              value: TimetableTabAction.copy,
              text: 'timetable.tab_menu.copy'.tr(),
              icon: Icons.copy,
            ),
            ItemData(
              value: TimetableTabAction.exportImage,
              text: 'timetable.tab_menu.export_img'.tr(),
              icon: Icons.image_outlined,
            ),
            ItemData(
              value: TimetableTabAction.exportIcal,
              text: 'timetable.tab_menu.export_cal'.tr(),
              icon: Icons.calendar_today_outlined,
            ),
            if (i != 0) ...[
              ItemData(
                value: TimetableTabAction.delete,
                text: 'timetable.tab_menu.delete'.tr(),
                icon: Icons.delete_outlined,
                textColor: OTLColor.red,
              ),
            ],
          ],
          offsetFromLeft: true,
          onChanged: (action) {
            if (action != null) widget.onAction(action, i);
          },
        ),
      );
    }

    return Container(
      height: 28,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: OTLColor.pinksLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _index = i;
            widget.onTap(i);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: text,
        ),
      ),
    );
  }
}
