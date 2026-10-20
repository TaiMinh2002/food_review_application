import 'review_feed_repository.dart';

enum UserReviewFilter { all, withPhotos, edited }

class UserReviewSummary {
  const UserReviewSummary({
    required this.total,
    required this.withPhotos,
    required this.edited,
    this.isDemo = false,
  });
  final int total, withPhotos, edited;
  final bool isDemo;
}

/// Backend implementations must filter by owner BEFORE count/order/limit.
/// Cursors are opaque to presentation; counts cover the entire user's list.
abstract interface class UserReviewRepository {
  Future<UserReviewSummary> getUserReviewSummary(String userId);
  Future<ReviewPage> getUserReviews(
    String userId, {
    required UserReviewFilter filter,
    String? cursor,
    int pageSize = 10,
  });
  Stream<void> watchUserReviewChanges(String userId);
}
