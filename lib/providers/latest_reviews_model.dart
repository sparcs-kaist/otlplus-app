import 'package:flutter/material.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/review.dart';

class LatestReviewsModel extends ChangeNotifier {
  int _page = 0;
  int get page => _page;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Review> _latestReviews = <Review>[];
  List<Review> get latestReviews {
    if (_latestReviews.length == 0 && !_isLoading) loadLatestReviews();
    return _latestReviews;
  }

  Future<void> clear() async {
    _latestReviews.clear();
    _page = 0;
    await loadLatestReviews();
  }

  Future<void> loadLatestReviews() async {
    _isLoading = true;

    try {
      final response = await DioProvider().dio.get(
        API_REVIEW_URL,
        queryParameters: {
          "order": "-written_datetime",
          "offset": _page * 10,
          "limit": 10,
        },
      );
      final rawReviews = response.data as List;
      _latestReviews.addAll(
        rawReviews.map((review) => Review.fromJson(review)),
      );
      _page++;
      _isLoading = false;
      notifyListeners();
    } catch (exception) {
      print(exception);
      _isLoading = false;
    }
  }
}
