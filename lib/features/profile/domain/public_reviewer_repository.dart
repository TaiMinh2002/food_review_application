import '../../reviews/domain/review.dart';
import '../../reviews/domain/review_feed_repository.dart';

enum PublicReviewFilter { newest, ratingHigh, withPhotos }

/// Deliberately excludes email, account roles and private profile fields.
class PublicReviewer {
  const PublicReviewer({
    required this.id,
    required this.name,
    required this.reviewCount,
    required this.photoReviewCount,
    this.averageRating,
    this.photoUrl,
    this.handle,
    this.region,
    this.bio,
    this.featured,
    this.isDemo = false,
  });
  final String id, name;
  final String? photoUrl, handle, region, bio;
  final int reviewCount, photoReviewCount;
  final double? averageRating;
  final Review? featured;
  final bool isDemo;
}

/// Read capability separate from private user-review management. Implementations
/// query only published, visible content before count/filter/order/limit.
abstract interface class PublicReviewerRepository {
  Future<PublicReviewer?> getPublicReviewer(String userId);
  Future<ReviewPage> getPublicReviews(
    String userId, {
    PublicReviewFilter filter = PublicReviewFilter.newest,
    String? cursor,
    int pageSize = 10,
  });
  Stream<void> watchPublicReviewerChanges(String userId);
}
