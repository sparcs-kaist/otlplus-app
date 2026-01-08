import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/extensions/review.dart';
import 'package:otlplus/extensions/semester.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:otlplus/widgets/expandable_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mailto/mailto.dart';

class ReviewBlock extends StatefulWidget {
  final Review review;
  final VoidCallback? onTap;
  final int maxLines = 5;

  ReviewBlock({required this.review, this.onTap});

  @override
  _ReviewBlockState createState() => _ReviewBlockState();
}

class _ReviewBlockState extends State<ReviewBlock> {
  late int _like;
  late bool _liked;

  @override
  void initState() {
    super.initState();
    _like = widget.review.like;
    _liked = widget.review.userspecificIsLiked;
  }

  @override
  Widget build(BuildContext context) {
    String content = widget.review.content;
    final isEn = EasyLocalization.of(context)?.currentLocale == Locale('en');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            BackgroundButton(
              color: OTLColor.grayE,
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text.rich(
                      TextSpan(
                        style: bodyRegular,
                        children: <TextSpan>[
                          TextSpan(
                            text: isEn
                                ? widget.review.lecture.titleEn
                                : widget.review.lecture.title,
                            style: bodyBold,
                          ),
                          const TextSpan(text: " "),
                          TextSpan(
                            text: widget.review.lecture.professors
                                .map(
                                  (professor) => isEn
                                      ? (professor.nameEn == ''
                                            ? professor.name
                                            : professor.nameEn)
                                      : professor.name,
                                )
                                .join(" "),
                          ),
                          const TextSpan(text: " "),
                          TextSpan(text: widget.review.lecture.year.toString()),
                          const TextSpan(text: " "),
                          TextSpan(
                            text: [
                              "",
                              "semester.spring".tr(),
                              "semester.summer".tr(),
                              "semester.fall".tr(),
                              "semester.winter".tr(),
                            ][widget.review.lecture.semester],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    ExpandableText(
                      content.trim(),
                      maxLines: widget.maxLines,
                      style: bodyRegular.copyWith(color: OTLColor.gray0),
                    ),
                    const SizedBox(height: 6.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text.rich(
                          TextSpan(
                            style: labelRegular,
                            children: <TextSpan>[
                              TextSpan(text: "review.likes".tr()),
                              const TextSpan(text: " "),
                              TextSpan(
                                text: _like.toString(),
                                style: labelBold,
                              ),
                              const TextSpan(text: "  "),
                              TextSpan(text: "review.grade".tr()),
                              const TextSpan(text: " "),
                              TextSpan(
                                text: widget.review.gradeLetter,
                                style: labelBold,
                              ),
                              const TextSpan(text: "  "),
                              TextSpan(text: "review.load".tr()),
                              const TextSpan(text: " "),
                              TextSpan(
                                text: widget.review.loadLetter,
                                style: labelBold,
                              ),
                              const TextSpan(text: "  "),
                              TextSpan(text: "review.speech".tr()),
                              const TextSpan(text: " "),
                              TextSpan(
                                text: widget.review.speechLetter,
                                style: labelBold,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTextButton(
                  color: OTLColor.pinksMain,
                  iconSize: 16.0,
                  icon: _liked
                      ? Icons.thumb_up_alt
                      : Icons.thumb_up_alt_outlined,
                  spaceBetween: 4.0,
                  text: "review.like".tr(),
                  textStyle: labelRegular,
                  padding: EdgeInsets.fromLTRB(3, 8, 10, 8),
                  onTap: _liked ? _uploadCancel : _uploadLike,
                ),
                IconTextButton(
                  color: OTLColor.gray5,
                  text: "review.report".tr(),
                  textStyle: labelRegular,
                  onTap: _report,
                  padding: EdgeInsets.fromLTRB(3, 8, 10, 8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadLike() async {
    setState(() {
      _like++;
      _liked = true;
    });

    await DioProvider().dio.post(
      API_REVIEW_LIKE_URL.replaceFirst("{id}", widget.review.id.toString()),
      data: {},
    );
  }

  Future<void> _uploadCancel() async {
    setState(() {
      _like--;
      _liked = false;
    });

    await DioProvider().dio.delete(
      API_REVIEW_LIKE_URL.replaceFirst("{id}", widget.review.id.toString()),
      data: {},
    );
  }

  void _report() {
    final lecture = widget.review.lecture;
    final isKo = context.locale == Locale('ko');
    launchUrl(
      Uri.parse(
        '${Mailto(
          to: [CONTACT],
          subject: 'review.mailto.subject'.tr(),
          body: 'review.mailto.body_reason'.tr() + 'review.mailto.body_info'.tr(
                namedArgs: {
                  'title': isKo ? lecture.title : lecture.titleEn,
                  'oldCode': lecture.oldCode,
                  'semesterTitle': Semester(year: lecture.year, semester: lecture.semester, beginning: DateTime(0), end: DateTime(0)).title,
                  'professors': lecture.professors.map((e) => isKo ? e.name : e.nameEn).join(', '),
                  'content': widget.review.content,
                },
              ),
        )}',
      ),
    );
  }
}
