import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/widgets/responsive_button.dart';

const _customBlockColor = Color(0xFFD4E6F1);

class CustomBlockTile extends StatelessWidget {
  final CustomBlock block;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  CustomBlockTile({
    Key? key,
    required this.block,
    this.height = 78,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final contents = <Widget>[];

    contents.add(
      Text(
        block.blockName,
        style: labelRegular.copyWith(
          color: OTLColor.gray0,
          overflow: TextOverflow.ellipsis,
        ),
        maxLines: 2,
      ),
    );

    if (block.place.isNotEmpty) {
      contents.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              block.place,
              style: labelRegular.copyWith(
                color: OTLColor.gray6,
                overflow: TextOverflow.ellipsis,
                fontSize: 10,
              ),
              maxLines: 1,
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(2.0),
      child: BackgroundButton(
        color: _customBlockColor,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: contents,
          ),
        ),
      ),
    );
  }
}
