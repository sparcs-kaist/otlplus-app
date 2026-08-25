import 'dart:async';

import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/latest_reviews_model.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/hall_of_fame_control.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:otlplus/widgets/review_block.dart';
import 'package:otlplus/widgets/review_mode_control.dart';
import 'package:provider/provider.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  static String route = 'review_page';

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadSelectedFeed());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadSelectedFeed() {
    return switch (context.read<HallOfFameModel>().selectedMode) {
      ReviewTab.hallOfFame => context.read<HallOfFameModel>().load(),
      ReviewTab.latest => context.read<LatestReviewsModel>().load(),
    };
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 200) {
      return;
    }

    switch (context.read<HallOfFameModel>().selectedMode) {
      case ReviewTab.hallOfFame:
        final model = context.read<HallOfFameModel>();
        if (model.hasMore && !model.isLoading) unawaited(model.loadMore());
        break;
      case ReviewTab.latest:
        final model = context.read<LatestReviewsModel>();
        if (model.hasMore && !model.isLoading) unawaited(model.loadMore());
        break;
    }
  }

  void _handleModeChanged(ReviewTab mode) {
    final hallOfFameModel = context.read<HallOfFameModel>();
    if (hallOfFameModel.selectedMode == mode) return;

    hallOfFameModel.setMode(mode);
    unawaited(_scrollToTop());
    unawaited(_loadSelectedFeed());
  }

  void _handleSemesterChanged(Semester? semester) {
    unawaited(_selectSemester(semester));
  }

  Future<void> _selectSemester(Semester? semester) async {
    final model = context.read<HallOfFameModel>();
    model.setSemester(semester);
    await _scrollToTop();
    await model.refresh();
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMode = context.select<HallOfFameModel, ReviewTab>(
      (model) => model.selectedMode,
    );
    final selectedSemester = context.select<HallOfFameModel, Semester?>(
      (model) => model.semester,
    );

    return OTLLayout(
      leading: ReviewModeControl(
        selectedMode: selectedMode,
        onChanged: _handleModeChanged,
      ),
      trailing: Visibility(
        visible: selectedMode == ReviewTab.hallOfFame,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: HallOfFameControl(
            selectedSemester: selectedSemester,
            onChanged: _handleSemesterChanged,
          ),
        ),
      ),
      body: Card(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              switch (selectedMode) {
                ReviewTab.hallOfFame => HallOfFamePage(
                  scrollController: _scrollController,
                ),
                ReviewTab.latest => LatestReviewsPage(
                  scrollController: _scrollController,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class LatestReviewsPage extends StatelessWidget {
  const LatestReviewsPage({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LatestReviewsModel>();
    final reviews = model.latestReviews;

    return Expanded(
      child: RefreshIndicator(
        onRefresh: model.refresh,
        child: Scrollbar(
          controller: scrollController,
          child: CustomScrollView(
            key: const Key('review_list'),
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= reviews.length) return null;
                  return ReviewBlock(
                    review: reviews[index],
                    onTap: () async {
                      context.read<CourseDetailModel>().loadCourse(
                        reviews[index].course.id,
                      );
                      OTLNavigator.push(context, CourseDetailPage());
                    },
                  );
                }, childCount: reviews.length),
              ),
              if (model.isLoading) const _LoadingSliver(),
            ],
          ),
        ),
      ),
    );
  }
}

class HallOfFamePage extends StatelessWidget {
  const HallOfFamePage({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HallOfFameModel>();
    final reviews = model.hallOfFame;

    return Expanded(
      child: RefreshIndicator(
        onRefresh: model.refresh,
        child: Scrollbar(
          controller: scrollController,
          child: CustomScrollView(
            key: const Key('review_list'),
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= reviews.length) return null;
                  return ReviewBlock(
                    review: reviews[index],
                    onTap: () async {
                      context.read<CourseDetailModel>().loadCourse(
                        reviews[index].course.id,
                      );
                      OTLNavigator.push(context, CourseDetailPage());
                    },
                  );
                }, childCount: reviews.length),
              ),
              if (model.isLoading) const _LoadingSliver(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingSliver extends StatelessWidget {
  const _LoadingSliver();

  @override
  Widget build(BuildContext context) {
    return const SliverToBoxAdapter(
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
    );
  }
}
