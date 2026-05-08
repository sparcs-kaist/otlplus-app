import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/theme/context_ext.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/widgets/dropdown.dart';

class TimetableTabs extends StatefulWidget {
  final int index;
  final int length;
  final Function(int) onTap;
  final VoidCallback onCopyTap;
  final Function(int) onDeleteTap;
  final Function(ShareType) onExportTap;

  TimetableTabs({
    this.index = 0,
    required this.length,
    required this.onTap,
    required this.onCopyTap,
    required this.onDeleteTap,
    required this.onExportTap,
  });

  @override
  _TimetableTabsState createState() => _TimetableTabsState();
}

class _TimetableTabsState extends State<TimetableTabs> {
  int _index = 0;
  ScrollController _scrollController = ScrollController();

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
            color: context.colors.backgroundPageDefault,
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
      style: context.texts.normalBold.copyWith(
        color: i == _index
            ? context.colors.textBright
            : context.colors.textDark,
      ),
      textAlign: TextAlign.center,
    );

    if (i == _index) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Dropdown<int>(
          customButton: Container(
            height: 28,
            padding: EdgeInsets.fromLTRB(12, 0, 8, 0),
            decoration: BoxDecoration(
              color: context.colors.highlightDefault,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                text,
                const SizedBox(width: 6),
                Icon(
                  Icons.more_vert,
                  color: context.colors.textBright,
                  size: 16,
                ),
              ],
            ),
          ),
          items: [
            ItemData(
              value: 0,
              text: 'timetable.tab_menu.copy'.tr(),
              icon: Icons.copy,
            ),
            ItemData(
              value: 1,
              text: 'timetable.tab_menu.export_img'.tr(),
              icon: Icons.image_outlined,
            ),
            ItemData(
              value: 2,
              text: 'timetable.tab_menu.export_cal'.tr(),
              icon: Icons.calendar_today_outlined,
            ),
            if (i != 0) ...[
              ItemData(
                value: 3,
                text: 'timetable.tab_menu.delete'.tr(),
                icon: Icons.delete_outlined,
                textColor: OTLColor.red, // legacy: no web red semantic
              ),
            ],
          ],
          offsetFromLeft: true,
          onChanged: (value) {
            if (value == 0) widget.onCopyTap();
            if (value == 1) widget.onExportTap(ShareType.image);
            if (value == 2) widget.onExportTap(ShareType.ical);
            if (value == 3) widget.onDeleteTap(i);
          },
        ),
      );
    }

    return Container(
      height: 28,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: context.colors.backgroundPageDefault,
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
