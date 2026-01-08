import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';

class CustomHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget Function(double) builder;
  final double height;
  final EdgeInsetsGeometry? padding;

  CustomHeaderDelegate({
    required this.builder,
    required this.height,
    this.padding,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: OTLColor.grayF,
      padding: padding,
      transform: Matrix4.translationValues(0, -1, 0),
      child: Material(color: Colors.transparent, child: builder(shrinkOffset)),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}
