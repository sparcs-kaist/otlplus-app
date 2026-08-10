import 'package:flutter/material.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/models/user.dart';

class LikedReviewModel extends ChangeNotifier {
  int _page = 0;
  int get page => _page;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Review> _likedReviews = <Review>[];
  List<Review> likedReviews(User _user) {
    if (_likedReviews.length == 0 && !_isLoading) loadLikedReviews(_user);
    return _likedReviews;
  }

  Future<void> clear(User _user) async {
    _likedReviews.clear();
    _page = 0;
    await loadLikedReviews(_user);
  }

  Future<void> loadLikedReviews(User _user) async {
    _isLoading = true;

    try {
      final response = await DioProvider().dio.get(
        API_LIKED_REVIEW_URL.replaceFirst("{user_id}", _user.id.toString()),
        queryParameters: {
          "order": "-written_datetime",
          "offset": _page * 10,
          "limit": 10,
        },
      );
      final rawReviews = response.data as List;
      _likedReviews.addAll(rawReviews.map((review) => Review.fromJson(review)));
      _page++;
      _isLoading = false;
      notifyListeners();
    } catch (exception) {
      print(exception);
      _isLoading = false;
      notifyListeners();
    }
  }
}
