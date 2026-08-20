import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/text_styles.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/liked_review_model.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:otlplus/widgets/review_block.dart';
import 'package:provider/provider.dart';

class LikedReviewPage extends StatefulWidget {
  const LikedReviewPage({super.key});

  static String route = 'liked_review_page';

  @override
  State<LikedReviewPage> createState() => _LikedReviewPageState();
}

class _LikedReviewPageState extends State<LikedReviewPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<InfoModel>().user.id;
      unawaited(context.read<LikedReviewModel>().load(userId));
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 200) {
      return;
    }

    final model = context.read<LikedReviewModel>();
    if (model.hasMore && !model.isLoading) unawaited(model.loadMore());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<InfoModel>().user;
    final model = context.watch<LikedReviewModel>();
    final reviews = model.likedReviews;

    return OTLScaffold(
      child: OTLLayout(
        middle: Text('user.liked_review'.tr(), style: titleBold),
        body: Container(
          constraints: const BoxConstraints.expand(),
          child: Card(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => model.refresh(user.id),
                      child: Scrollbar(
                        controller: _scrollController,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                return ReviewBlock(
                                  review: reviews[index],
                                  onTap: () async {
                                    context
                                        .read<CourseDetailModel>()
                                        .loadCourse(reviews[index].course.id);
                                    OTLNavigator.push(
                                      context,
                                      CourseDetailPage(),
                                      transition:
                                          OTLNavigatorTransition.rightLeft,
                                    );
                                  },
                                );
                              }, childCount: reviews.length),
                            ),
                            if (model.isLoading)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 4, bottom: 12),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: OTLColor.grayE,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
