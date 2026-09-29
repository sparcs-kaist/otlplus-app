import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/models/custom_block.dart';

class CustomBlockTile extends StatelessWidget {
  const CustomBlockTile({super.key, required this.block, this.onTap});
  final CustomBlock block;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '${block.name}, ${block.place}',
    button: onTap != null,
    child: Material(
      color: OTLColor
          .blockColors[(block.id * 3 + 7) % OTLColor.blockColors.length],
      borderRadius: BorderRadius.circular(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: ClipRect(
            child: Text(
              '${block.name}${block.place.isEmpty ? '' : '\n${block.place}'}',
              style: const TextStyle(fontSize: 10, color: OTLColor.gray3),
              overflow: TextOverflow.clip,
            ),
          ),
        ),
      ),
    ),
  );
}
