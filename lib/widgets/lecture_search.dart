import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/pages/lecture_search_page.dart';
import 'package:otlplus/widgets/responsive_button.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/widgets/lecture_group_block.dart';

class LectureSearch extends StatefulWidget {
  final Future<bool> Function()? onClosed;
  const LectureSearch({Key? key, this.onClosed}) : super(key: key);

  @override
  _LectureSearchState createState() => _LectureSearchState();
}

class _LectureSearchState extends State<LectureSearch> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchModel = context.watch<LectureSearchModel>();

    return PopScope(
      onPopInvokedWithResult: (_, __) {
        if (widget.onClosed != null) {
          widget.onClosed!();
        }
      },
      child: ColoredBox(
        color: OTLColor.grayF,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      child: BackgroundButton(
                        onTap: () => OTLNavigator.push(
                          context,
                          LectureSearchPage(openKeyboard: true),
                        ),
                        color: OTLColor.pinksLight,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            height: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
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
                                SizedBox(width: 12.0),
                                Flexible(
                                  child: context
                                      .watch<LectureSearchModel>()
                                      .lectureSearchquery,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconTextButton(
                  padding: EdgeInsets.fromLTRB(8, 12, 16, 12),
                  icon: Icons.close_outlined,
                  iconSize: 24,
                  onTap: widget.onClosed,
                ),
              ],
            ),
            Expanded(
              child: searchModel.isSearching
                  ? Center(child: const CircularProgressIndicator())
                  : Scrollbar(
                      controller: _scrollController,
                      child: _buildListView(
                        searchModel.lectures ?? [[]],
                        _scrollController,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  ListView _buildListView(
    List<List<Lecture>> lectures,
    ScrollController scrollController,
  ) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      controller: scrollController,
      itemCount: lectures.length,
      itemBuilder: (context, index) => LectureGroupBlock(
        lectures: lectures[index],
        onLongPress: (lecture) {
          context.read<LectureDetailModel>().loadLecture(lecture.id, true);
          OTLNavigator.push(context, LectureDetailPage());
        },
      ),
      separatorBuilder: (context, index) => SizedBox(height: 8),
    );
  }
}
