import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/models/course.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/pages/course_search_page.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/widgets/course_block.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:provider/provider.dart';

class DictionaryPage extends StatefulWidget {
  static String route = 'dictionary_page';

  const DictionaryPage({Key? key}) : super(key: key);

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final searchModel = context.watch<CourseSearchModel>();
    final courseSnapshot = searchModel.courses;
    final courses = courseSnapshot ?? const <Course>[];

    return OTLLayout(
      middle: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: BackgroundButton(
            tapEffectColorRatio: 0.04,
            onTap: () => OTLNavigator.push(context, CourseSearchPage()),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/search.svg',
                    height: 24.0,
                    width: 24.0,
                    colorFilter: ColorFilter.mode(
                      OTLColor.pinksMain,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(child: _buildCourseSearchSummary(searchModel)),
                ],
              ),
            ),
            color: OTLColor.grayF,
          ),
        ),
      ),
      body: ColoredBox(
        color: OTLColor.grayF,
        child: Builder(
          builder: (context) {
            if (searchModel.isSearching) {
              return const Center(child: CircularProgressIndicator());
            } else if (courseSnapshot == null) {
              return Center(child: _buildCopyRight());
            } else if (courses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "common.no_result".tr(),
                      style: bodyRegular.copyWith(color: OTLColor.grayA),
                    ),
                  ],
                ),
              );
            } else {
              return Scrollbar(
                controller: _scrollController,
                child: ListView.separated(
                  key: const Key('dictionary_list'),
                  controller: _scrollController,
                  padding: EdgeInsets.all(12.0),
                  itemCount: courses.length,
                  itemBuilder: (context, index) => CourseBlock(
                    course: courses[index],
                    onTap: () {
                      context.read<CourseDetailModel>().loadCourse(
                        courses[index].id,
                      );
                      OTLNavigator.push(context, CourseDetailPage());
                    },
                  ),
                  separatorBuilder: (context, index) => SizedBox(height: 8.0),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

Widget _buildCourseSearchSummary(CourseSearchModel model) {
  final labelKeys = model.selectedFilterLabelKeys;
  if (model.searchText.isEmpty && labelKeys.isEmpty) {
    return Text(
      "common.search_hint".tr(),
      style: bodyRegular.copyWith(color: OTLColor.grayA),
    );
  }

  return Text.rich(
    TextSpan(
      style: bodyRegular.copyWith(color: OTLColor.grayA),
      children: <InlineSpan>[
        TextSpan(text: model.searchText.isEmpty ? "" : '"${model.searchText}"'),
        if (labelKeys.isNotEmpty && model.searchText.isNotEmpty)
          const TextSpan(text: ", "),
        TextSpan(text: labelKeys.map((key) => key.tr()).join(", ")),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

Widget _buildCopyRight() {
  return Text.rich(
    TextSpan(
      style: labelRegular.copyWith(color: OTLColor.grayA),
      children: [
        TextSpan(text: 'otlplus@sparcs.org'),
        TextSpan(text: '\n'),
        TextSpan(text: '© 2023 SPARCS OTL Team'),
      ],
    ),
    textAlign: TextAlign.center,
  );
}
