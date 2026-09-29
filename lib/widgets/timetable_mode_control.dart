import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/enums.dart';

class TimetableModeControl extends StatefulWidget {
  const TimetableModeControl({
    Key? key,
    this.selectedMode = TimetableViewMode.classes,
    required this.onTap,
  }) : super(key: key);
  final TimetableViewMode selectedMode;
  final ValueChanged<TimetableViewMode> onTap;

  @override
  State<TimetableModeControl> createState() => _TimetableModeControlState();
}

class _TimetableModeControlState extends State<TimetableModeControl> {
  static const Map<TimetableViewMode, IconData> _icons = {
    TimetableViewMode.classes: Icons.schedule,
    TimetableViewMode.exams: Icons.menu_book,
    TimetableViewMode.map: Icons.map_outlined,
  };

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
          AnimatedPositionedDirectional(
            start: 48.0 * widget.selectedMode.index,
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
          Row(
            children: TimetableViewMode.values.map((mode) {
              return GestureDetector(
                onTap: () => widget.onTap(mode),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 48,
                  height: 32,
                  child: Center(
                    child: Icon(
                      _icons[mode],
                      size: 24,
                      color: mode == widget.selectedMode
                          ? OTLColor.grayF
                          : OTLColor.pinksMain,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
