import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:otlplus/theme/context_ext.dart';

class SearchTextfield extends StatefulWidget {
  const SearchTextfield({
    Key? key,
    this.textController,
    this.focusNode,
    this.backgroundColor,
    this.autoFocus = false,
  }) : super(key: key);
  final TextEditingController? textController;
  final FocusNode? focusNode;
  final Color? backgroundColor;
  final bool? autoFocus;

  @override
  State<SearchTextfield> createState() => _SearchTextfieldState();
}

class _SearchTextfieldState extends State<SearchTextfield> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: ColoredBox(
        color: context.colors.backgroundSectionDefault,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/search.svg',
                height: 24.0,
                width: 24.0,
                colorFilter: ColorFilter.mode(
                  context.colors.highlightDefault,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: TextField(
                  autofocus: widget.autoFocus ?? false,
                  controller: widget.textController,
                  focusNode: widget.focusNode,
                  onSubmitted: (value) {
                    widget.focusNode?.unfocus();
                  },
                  style: context.texts.normal,
                  decoration: InputDecoration(
                    hintText: "common.search_hint".tr(),
                    hintStyle: context.texts.normal.copyWith(
                      color: context.colors.textPlaceholder,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
