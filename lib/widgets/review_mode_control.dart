import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:provider/provider.dart';

class ReviewModeControl extends StatefulWidget {
  const ReviewModeControl({
    Key? key,
    ReviewTab selectedMode = ReviewTab.hallOfFame,
  }) : _selectedMode = selectedMode,
       super(key: key);
  final ReviewTab _selectedMode;

  @override
  State<ReviewModeControl> createState() => _ReviewModeControlState();
}

class _ReviewModeControlState extends State<ReviewModeControl> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      decoration: BoxDecoration(
        color: OTLColor.grayF,
        borderRadius: BorderRadius.horizontal(right: Radius.circular(21)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context
                    .read<HallOfFameModel>()
                    .setMode(ReviewTab.hallOfFame),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 34,
                  width: widget._selectedMode == ReviewTab.latest ? 48 : 0,
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: widget._selectedMode == ReviewTab.latest
                      ? Icon(
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
                padding: EdgeInsets.only(left: 12.0, right: 16.0),
                child: Row(
                  children: [
                    Icon(
                      widget._selectedMode == ReviewTab.hallOfFame
                          ? Icons.emoji_events_outlined
                          : Icons.whatshot_outlined,
                      color: OTLColor.grayF,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget._selectedMode == ReviewTab.hallOfFame
                          ? "title.hall_of_fame".tr()
                          : "title.latest_reviews".tr(),
                      style: titleBold.copyWith(color: OTLColor.grayF),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context
                    .read<HallOfFameModel>()
                    .setMode(ReviewTab.latest),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 34,
                  width: widget._selectedMode == ReviewTab.hallOfFame ? 48 : 0,
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  child: widget._selectedMode == ReviewTab.hallOfFame
                      ? Icon(Icons.whatshot_outlined, color: OTLColor.pinksMain)
                      : null,
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            left: widget._selectedMode == ReviewTab.latest ? 48.0 : 0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: OTLColor.pinksMain,
                borderRadius: BorderRadius.circular(17),
              ),
              padding: EdgeInsets.only(left: 12.0, right: 16.0),
              child: Row(
                children: [
                  Icon(
                    widget._selectedMode == ReviewTab.hallOfFame
                        ? Icons.emoji_events_outlined
                        : Icons.whatshot_outlined,
                    color: OTLColor.grayF,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget._selectedMode == ReviewTab.hallOfFame
                        ? "title.hall_of_fame".tr()
                        : "title.latest_reviews".tr(),
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
