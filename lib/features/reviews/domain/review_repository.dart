import 'review.dart';

abstract interface class ReviewRepository {
  Stream<List<Review>> watchForPlace(String placeId, {int limit = 20});
  Future<void> create(Review review);
}

/// Account-scoped mutations. Implementations must enforce ownership server-side.
abstract interface class ReviewManagementRepository {
  Stream<List<Review>> watchForUser(String userId);
  Future<Review?> getReview(String placeId, String reviewId);
  Future<void> update(Review review);
  Future<void> delete({
    required String userId,
    required String placeId,
    required String reviewId,
  });
}

/// Exact scoped lookup; a bounded preview cannot resolve arbitrary review IDs.
abstract interface class ReviewMediaRepository {
  Future<Review?> getReview(String placeId, String reviewId);
}
