import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/constants/text_styles.dart';

class ReviewModeControl extends StatelessWidget {
  const ReviewModeControl({
    required this.selectedMode,
    required this.onChanged,
    super.key,
  });

  final ReviewTab selectedMode;
  final ValueChanged<ReviewTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      decoration: const BoxDecoration(
        color: OTLColor.grayF,
        borderRadius: BorderRadius.horizontal(right: Radius.circular(21)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => onChanged(ReviewTab.hallOfFame),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 34,
                  width: selectedMode == ReviewTab.latest ? 48 : 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  child: selectedMode == ReviewTab.latest
                      ? const Icon(
                          Icons.emoji_events_outlined,
                          color: OTLColor.pinksMain,
                        )
                      : null,
                ),
              ),
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: OTLColor.grayF,
                  borderRadius: BorderRadius.circular(17),
                ),
                padding: const EdgeInsets.only(left: 12, right: 16),
                child: Row(
                  children: [
                    Icon(
                      selectedMode == ReviewTab.hallOfFame
                          ? Icons.emoji_events_outlined
                          : Icons.whatshot_outlined,
                      color: OTLColor.grayF,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedMode == ReviewTab.hallOfFame
                          ? 'title.hall_of_fame'.tr()
                          : 'title.latest_reviews'.tr(),
                      style: titleBold.copyWith(color: OTLColor.grayF),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(ReviewTab.latest),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 34,
                  width: selectedMode == ReviewTab.hallOfFame ? 48 : 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  child: selectedMode == ReviewTab.hallOfFame
                      ? const Icon(
                          Icons.whatshot_outlined,
                          color: OTLColor.pinksMain,
                        )
                      : null,
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            left: selectedMode == ReviewTab.latest ? 48 : 0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: OTLColor.pinksMain,
                borderRadius: BorderRadius.circular(17),
              ),
              padding: const EdgeInsets.only(left: 12, right: 16),
              child: Row(
                children: [
                  Icon(
                    selectedMode == ReviewTab.hallOfFame
                        ? Icons.emoji_events_outlined
                        : Icons.whatshot_outlined,
                    color: OTLColor.grayF,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedMode == ReviewTab.hallOfFame
                        ? 'title.hall_of_fame'.tr()
                        : 'title.latest_reviews'.tr(),
                    style: titleBold.copyWith(color: OTLColor.grayF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
