import 'review.dart';

abstract interface class ReviewRepository {
  Stream<List<Review>> watchForPlace(String placeId, {int limit = 20});
  Future<void> create(Review review);
}

/// Exact scoped lookup; a bounded preview cannot resolve arbitrary review IDs.
abstract interface class ReviewMediaRepository {
  Future<Review?> getReview(String placeId, String reviewId);
}
