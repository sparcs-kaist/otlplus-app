import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:otlplus/theme/context_ext.dart';
import 'package:otlplus/models/classtime.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/utils/get_text_height.dart';

const POSITION_OF_LOCATIONS = {
  'E2': {'left': 0.599, 'top': 0.802},
  'E3': {'left': 0.668, 'top': 0.744},
  'E6': {'left': 0.685, 'top': 0.668},
  'E6-5': {'left': 0.651, 'top': 0.573},
  'E7': {'left': 0.771, 'top': 0.592},
  'E11': {'left': 0.531, 'top': 0.573},
  'E16': {'left': 0.531, 'top': 0.515},
  'N1': {'left': 0.873, 'top': 0.382},
  'N2': {'left': 0.719, 'top': 0.458},
  'N3': {'left': 0.531, 'top': 0.439},
  'N4': {'left': 0.634, 'top': 0.401},
  'N5': {'left': 0.771, 'top': 0.382},
  'N7': {'left': 0.325, 'top': 0.401},
  'N7-2': {'left': 0.291, 'top': 0.42},
  'N22': {'left': 0.788, 'top': 0.344},
  'N24': {'left': 0.753, 'top': 0.305},
  'N25': {'left': 0.582, 'top': 0.363},
  'N27': {'left': 0.565, 'top': 0.229},
  'W1': {'left': 0.308, 'top': 0.821},
  'W1-1': {'left': 0.291, 'top': 0.878},
  'W1-2': {'left': 0.342, 'top': 0.84},
  'W1-3': {'left': 0.36, 'top': 0.802},
  'W8': {'left': 0.308, 'top': 0.592},
  'W16': {'left': 0.394, 'top': 0.859},
};

Color _blockColor(BuildContext context, int i) {
  final c = context.colors;
  switch (i % 16) {
    case 0:
      return c.tileTimetableRed1;
    case 1:
      return c.tileTimetableRed2;
    case 2:
      return c.tileTimetableOrange1;
    case 3:
      return c.tileTimetableOrange2;
    case 4:
      return c.tileTimetableYellow1;
    case 5:
      return c.tileTimetableYellow2;
    case 6:
      return c.tileTimetableGreen1;
    case 7:
      return c.tileTimetableGreen2;
    case 8:
      return c.tileTimetableGreen3;
    case 9:
      return c.tileTimetableBlue1;
    case 10:
      return c.tileTimetableBlue2;
    case 11:
      return c.tileTimetablePurple1;
    case 12:
      return c.tileTimetablePurple2;
    case 13:
      return c.tileTimetablePurple2;
    case 14:
      return c.tileTimetablePink1;
    default:
      return c.tileTimetablePink2;
  }
}

class MapView extends StatefulWidget {
  final Map<String, List<Map<Lecture, Classtime>>> _lectures = {};

  Map<String, List<Map<Lecture, Classtime>>> get lectures => _lectures;

  MapView({required List<Lecture> lectures}) {
    for (Lecture lecture in lectures) {
      for (Classtime classtime in lecture.classtimes) {
        String buildingCode = classtime.buildingCode;
        if (buildingCode == '') buildingCode = '기타';
        if ((_lectures[buildingCode]?.indexWhere(
                  (element) =>
                      element.values.first.classroom == classtime.classroom,
                ) ??
                -1) ==
            -1)
          _lectures[buildingCode] =
              _lectures[buildingCode]?.followedBy([
                {lecture: classtime},
              ]).toList() ??
              [
                {lecture: classtime},
              ];
      }
    }
  }

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late double _width, _height;
  late List<String> _pinOrder, _blockOrder;
  late bool _isKo;

  @override
  void initState() {
    super.initState();
    _blockOrder = POSITION_OF_LOCATIONS.keys.toList();
    _blockOrder.add('기타');
    _pinOrder = [..._blockOrder.reversed];
  }

  @override
  Widget build(BuildContext context) {
    final List<String> pinKeys, blockKeys;
    pinKeys = widget.lectures.keys.toList()
      ..sort((a, b) {
        return _pinOrder.indexOf(a).compareTo(_pinOrder.indexOf(b));
      });
    blockKeys = widget.lectures.keys.toList()
      ..sort((a, b) {
        return _blockOrder.indexOf(a).compareTo(_blockOrder.indexOf(b));
      });

    _width = MediaQuery.of(context).size.width - 100;
    _height = _width * 131 / 146;

    _isKo = context.locale == Locale('ko');

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: CustomHeaderDelegate(
            widget: Container(
              height: _height + 12,
              padding: EdgeInsets.fromLTRB(50, 0, 50, 12),
              color: context.colors.backgroundSectionDefault,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomLeft,
                children: <Widget>[
                  Image.asset('assets/images/kaist_map.png'),
                  ...List.generate(
                    pinKeys.length,
                    (i) => _buildMapPin(context, pinKeys[i]),
                  ),
                ],
              ),
            ),
            extent: _height + 12,
          ),
        ),
        SliverList.builder(
          itemCount: blockKeys.length,
          itemBuilder: (_, i) => _buildBuildingBlock(blockKeys[i]),
        ),
      ],
    );
  }

  Widget _buildMapPin(BuildContext context, String buildingCode) {
    List<BoxShadow> boxShadow = [
      BoxShadow(
        color: context.colors.textDark.withValues(alpha: .25),
        blurRadius: 4,
        offset: Offset(0, 4),
      ),
    ];
    return Positioned(
      left:
          _width * (POSITION_OF_LOCATIONS[buildingCode]?['left'] ?? 0.031) - 9,
      top:
          _height * (POSITION_OF_LOCATIONS[buildingCode]?['top'] ?? 1.000) - 27,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 23,
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            decoration: BoxDecoration(
              color: context.colors.backgroundSectionDefault,
              borderRadius: BorderRadius.circular(1),
              boxShadow: boxShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (buildingCode != '기타')
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(buildingCode, style: context.texts.smallBold),
                  ),
                ...List.generate(
                  widget.lectures[buildingCode]!.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: _darken(
                          _blockColor(
                            context,
                            widget.lectures[buildingCode]![i].keys.first.course,
                          ),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 6,
            bottom: -4,
            child: Container(
              decoration: BoxDecoration(boxShadow: boxShadow),
              child: SvgPicture.asset('assets/icons/map_pin.svg'),
            ),
          ),
        ],
      ),
    );
  }

  String _codeToName(String buildingCode) {
    if (buildingCode == '기타') return _isKo ? '기타' : 'ETC';
    Classtime first = widget.lectures[buildingCode]![0].values.first;
    String buildingName = _isKo ? first.classroom : first.classroomEn;
    buildingName = buildingName.replaceAll('($buildingCode)', '');
    buildingName = buildingName.replaceAll(first.roomName, '');
    return buildingCode + ' ' + buildingName.trim();
  }

  Widget _buildBuildingBlock(String buildingCode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.lineDefault,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _pinOrder.remove(buildingCode);
                _pinOrder.add(buildingCode);
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _codeToName(buildingCode),
                    style: context.texts.normalBold,
                  ),
                  Divider(
                    height: 15,
                    thickness: 1,
                    color: context.colors.textDark.withValues(alpha: .25),
                  ),
                  const SizedBox(height: 1),
                  ...List.generate(
                    widget.lectures[buildingCode]!.length,
                    (i) => _buildLectureBlock(i, buildingCode),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _darken(Color originalColor) {
    HSLColor color = HSLColor.fromColor(originalColor);
    double saturation = color.saturation + 0.1;
    double lightness = color.lightness - 0.1;
    return color.withSaturation(saturation).withLightness(lightness).toColor();
  }

  Widget _buildLectureBlock(int i, String buildingCode) {
    Lecture lecture = widget.lectures[buildingCode]![i].keys.first;
    Classtime classtime = widget.lectures[buildingCode]![i].values.first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: _darken(_blockColor(context, lecture.course)),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              _isKo ? lecture.title : lecture.titleEn,
              style: context.texts.normal,
            ),
          ),
        ),
        if (classtime.roomName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 0, 0),
            child: Builder(
              builder: (context) {
                final location = (buildingCode == '기타')
                    ? _isKo
                          ? classtime.classroom
                          : classtime.classroomEn
                    : classtime.roomName;
                final isMultiLine =
                    (getTextSize(
                          context,
                          text: location,
                          style: context.texts.small,
                          maxWidth: 143,
                        ).height ~/
                        singleHeight(context, context.texts.small)) >
                    1;

                return Container(
                  width: isMultiLine ? 155 : null,
                  padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _blockColor(context, lecture.course),
                    borderRadius: BorderRadius.circular(isMultiLine ? 13 : 100),
                  ),
                  child: Text(location, style: context.texts.small),
                );
              },
            ),
          ),
      ],
    );
  }
}

class CustomTriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

class CustomHeaderDelegate extends SliverPersistentHeaderDelegate {
  CustomHeaderDelegate({required this.widget, required this.extent});

  Widget widget;
  double extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return widget;
  }

  @override
  double get maxExtent => extent;

  @override
  double get minExtent => extent;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
