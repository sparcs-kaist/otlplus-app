import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/extensions/locale.dart';

class ReviewWriteBlock extends StatefulWidget {
  final Lecture lecture;
  final Review? existingReview;
  final bool isSimple;
  final Future<void> Function()? onUploaded;

  ReviewWriteBlock({
    required this.lecture,
    this.existingReview,
    this.isSimple = false,
    this.onUploaded,
  });

  @override
  _ReviewWriteBlockState createState() => _ReviewWriteBlockState();
}

class _ReviewWriteBlockState extends State<ReviewWriteBlock> {
  final _scores = {"성적": 0, "널널": 0, "강의": 0};
  final _contentTextController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingReview != null) {
      _scores["성적"] = widget.existingReview!.grade;
      _scores["널널"] = widget.existingReview!.load;
      _scores["강의"] = widget.existingReview!.speech;
      _contentTextController.text = widget.existingReview!.content;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _contentTextController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.isEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: OTLColor.grayE,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!widget.isSimple)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text.rich(
                  TextSpan(
                    style: bodyRegular,
                    children: <TextSpan>[
                      TextSpan(
                        text: isEn
                            ? widget.lecture.titleEn
                            : widget.lecture.title,
                        style: bodyBold,
                      ),
                      const TextSpan(text: " "),
                      TextSpan(
                        text: widget.lecture.professors
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
                      TextSpan(text: widget.lecture.year.toString()),
                      const TextSpan(text: " "),
                      TextSpan(
                        text: [
                          "",
                          "semester.spring".tr(),
                          "semester.summer".tr(),
                          "semester.fall".tr(),
                          "semester.winter".tr(),
                        ][widget.lecture.semester],
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: DottedBorder(
                color: OTLColor.grayA,
                child: SizedBox(
                  height: 140,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: TextField(
                      controller: _contentTextController,
                      maxLines: null,
                      style: bodyRegular,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: "common.review_hint".tr(),
                        hintStyle: bodyRegular.copyWith(color: OTLColor.grayA),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildScore("성적"),
            _buildScore("널널"),
            _buildScore("강의"),
            Align(
              alignment: Alignment.bottomRight,
              child: IconTextButton(
                padding: EdgeInsets.zero,
                color: _canUpload() ? OTLColor.pinksMain : OTLColor.grayA,
                text: (widget.existingReview == null)
                    ? "common.upload".tr()
                    : "common.edit".tr(),
                onTap: _canUpload() ? _uploadReview : null,
                textStyle: labelRegular,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canUpload() {
    if (_isUploading) return false;
    if ((_scores["성적"] ?? -1) > 0 &&
        (_scores["널널"] ?? -1) > 0 &&
        (_scores["강의"] ?? -1) > 0 &&
        _contentTextController.text.isNotEmpty) {
      if (widget.existingReview != null) {
        return widget.existingReview?.content != _contentTextController.text ||
            _scores["성적"] != widget.existingReview?.grade ||
            _scores["널널"] != widget.existingReview?.load ||
            _scores["강의"] != widget.existingReview?.speech;
      }
      return true;
    }
    return false;
  }

  Future<void> _uploadReview() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final repository = context.read<ReviewRepository>();
      final grade = _scores["성적"]!;
      final load = _scores["널널"]!;
      final speech = _scores["강의"]!;

      if (widget.existingReview == null) {
        await repository.create(
          lectureId: widget.lecture.id,
          content: _contentTextController.text,
          grade: grade,
          load: load,
          speech: speech,
        );
      } else {
        await repository.update(
          reviewId: widget.existingReview!.id,
          content: _contentTextController.text,
          grade: grade,
          load: load,
          speech: speech,
        );
      }

      await widget.onUploaded?.call();
    } catch (exception) {
      print(exception);
      if (mounted) {
        final isEn = context.isEn;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn ? 'Failed to save review.' : '후기를 저장하지 못했습니다.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildScore(String type) {
    late String title;

    switch (type) {
      case "성적":
        title = "review.grade".tr();
        break;
      case "널널":
        title = "review.load".tr();
        break;
      case "강의":
        title = "review.speech".tr();
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: <Widget>[
          Text(title, style: bodyRegular),
          const SizedBox(width: 4.0),
          _buildOption(type, 5),
          _buildOption(type, 4),
          _buildOption(type, 3),
          _buildOption(type, 2),
          _buildOption(type, 1),
        ],
      ),
    );
  }

  Widget _buildOption(String type, int score) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: ClipOval(
        child: BackgroundButton(
          color: (_scores[type] == score) ? OTLColor.gray75 : OTLColor.grayD,
          onTap: () {
            setState(() {
              _scores[type] = (_scores[type] == score) ? 0 : score;
            });
          },
          child: SizedBox(
            width: 24.0,
            height: 24.0,
            child: Center(
              child: Text(
                ["?", "F", "D", "C", "B", "A"][score],
                style: labelBold.copyWith(
                  color: _scores[type] == score
                      ? OTLColor.grayF
                      : OTLColor.grayF,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
