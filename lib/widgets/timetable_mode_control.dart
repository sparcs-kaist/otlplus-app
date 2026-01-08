import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';

class TimetableModeControl extends StatefulWidget {
  const TimetableModeControl({
    Key? key,
    this.dropdownIndex = 0,
    required this.onTap,
  }) : super(key: key);
  final int dropdownIndex;
  final Function(int) onTap;

  @override
  State<TimetableModeControl> createState() => _TimetableModeControlState();
}

class _TimetableModeControlState extends State<TimetableModeControl> {
  static const List<String> _dropdownList = ['수업 시간표', '시험 시간표', '지도'];
  static const List<IconData> _iconList = [
    Icons.schedule,
    Icons.menu_book,
    Icons.map_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      height: 40,
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      decoration: BoxDecoration(
        color: OTLColor.grayF,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            left: 48.0 * widget.dropdownIndex,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: OTLColor.pinksMain,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dropdownList.length,
            itemBuilder: (_, index) {
              return GestureDetector(
                onTap: () => widget.onTap(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 32,
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: Icon(
                    _iconList[index],
                    color: (index == widget.dropdownIndex)
                        ? OTLColor.grayF
                        : OTLColor.pinksMain,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
