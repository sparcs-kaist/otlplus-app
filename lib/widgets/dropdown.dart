import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';

class ItemData<T> {
  final T value;
  final String text;
  final IconData? icon;
  final Color textColor, iconColor;
  final bool disabled;

  ItemData({
    required this.value,
    required this.text,
    this.icon,
    this.textColor = OTLColor.grayF,
    this.iconColor = OTLColor.grayF,
    this.disabled = false,
  });
}

class Dropdown<T> extends StatelessWidget {
  const Dropdown({
    Key? key,
    required this.customButton,
    required this.items,
    this.isIconLeft = false,
    this.offsetFromLeft = false,
    this.offsetY = -8,
    this.hasScrollbar = false,
    required this.onChanged,
    this.onMenuStateChange,
  }) : super(key: key);

  final Widget customButton;
  final List<ItemData<T>> items;
  final bool isIconLeft;
  final bool offsetFromLeft;
  final double offsetY;
  final bool hasScrollbar;
  final void Function(T?) onChanged;
  final void Function(bool)? onMenuStateChange;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        customButton: customButton,
        dropdownStyleData: DropdownStyleData(
          direction: offsetFromLeft
              ? DropdownDirection.right
              : DropdownDirection.left,
          width: 200,
          maxHeight: 237,
          elevation: 0,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: OTLColor.gray6,
          ),
          offset: Offset(0, offsetY),
          scrollbarTheme: hasScrollbar
              ? ScrollbarThemeData(
                  radius: Radius.circular(1.5),
                  mainAxisMargin: 11.5,
                  crossAxisMargin: 4.5,
                  thickness: WidgetStatePropertyAll(3),
                  thumbColor: WidgetStatePropertyAll(OTLColor.grayF),
                  interactive: true,
                )
              : null,
        ),
        menuItemStyleData: MenuItemStyleData(padding: EdgeInsets.zero),
        items: items.map((itemData) {
          final children = [
            Expanded(
              child: Text(
                itemData.text,
                style: bodyRegular.copyWith(color: itemData.textColor),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: isIconLeft ? 12 : 0),
              child: Icon(itemData.icon, size: 16, color: itemData.iconColor),
            ),
          ];
          return DropdownItem<T>(
            value: itemData.value,
            height: 42,
            child: Stack(
              alignment: AlignmentDirectional.bottomStart,
              children: [
                Opacity(
                  opacity: itemData.disabled ? 0.5 : 1,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: isIconLeft
                          ? children.reversed.toList()
                          : children,
                    ),
                  ),
                ),
                if (itemData != items.last)
                  Container(
                    color: OTLColor.grayF.withValues(alpha: .5),
                    height: 0.5,
                  ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        onMenuStateChange: onMenuStateChange,
      ),
    );
  }
}
