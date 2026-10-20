import '../../../core/errors/app_exception.dart';
import '../../profile/domain/public_reviewer_repository.dart';
import '../domain/review.dart';
import '../domain/review_feed_repository.dart';

/// Only explicitly illustrative reviews are public in this demo. New private
/// submissions must never become public solely because an author ID is known.
mixin DemoPublicReviewerQueries implements PublicReviewerRepository {
  List<Review> get publicReviewData;

  List<Review> _visible(String id) => publicReviewData
      .where((review) => review.userId == id && review.isDemo)
      .toList();

  @override
  Future<PublicReviewer?> getPublicReviewer(String userId) async {
    final reviews = _visible(userId);
    const names = {
      'linh-demo': 'Hoàng Linh',
      'nam-demo': 'Trần Nhật Nam',
      'chau-demo': 'Minh Châu',
      'hai-demo': 'Đặng Hải',
      'new-reviewer-demo': 'Thành viên mới',
    };
    // A missing/hidden account is not reconstructed from arbitrary private data.
    if (!names.containsKey(userId)) return null;
    reviews.sort((a, b) {
      final rating = b.rating.compareTo(a.rating);
      return rating != 0 ? rating : b.createdAt.compareTo(a.createdAt);
    });
    return PublicReviewer(
      id: userId,
      name: names[userId]!,
      handle: '@${userId.replaceAll('-demo', '.food')}',
      photoUrl: userId == 'linh-demo'
          ? 'assets/images/demo/reviewer_avatar.jpg'
          : null,
      region: 'Hà Nội',
      bio: 'Thích khám phá quán ngon và chia sẻ trải nghiệm chân thực.',
      reviewCount: reviews.length,
      photoReviewCount: reviews.where((r) => r.imageUrls.isNotEmpty).length,
      averageRating: reviews.isEmpty
          ? null
          : reviews.fold<int>(0, (sum, r) => sum + r.rating) / reviews.length,
      featured: reviews.where((r) => r.imageUrls.isNotEmpty).firstOrNull,
      isDemo: true,
    );
  }

  @override
  Future<ReviewPage> getPublicReviews(
    String userId, {
    PublicReviewFilter filter = PublicReviewFilter.newest,
    String? cursor,
    int pageSize = 10,
  }) async {
    if (pageSize < 1 || pageSize > 50) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
    final reviews = _visible(userId)
        .where(
          (r) =>
              filter != PublicReviewFilter.withPhotos || r.imageUrls.isNotEmpty,
        )
        .toList();
    reviews.sort((a, b) {
      final rating = filter == PublicReviewFilter.ratingHigh
          ? b.rating.compareTo(a.rating)
          : 0;
      if (rating != 0) return rating;
      final date = b.createdAt.compareTo(a.createdAt);
      return date != 0 ? date : a.id.compareTo(b.id);
    });
    var start = 0;
    if (cursor != null) {
      final index = reviews.indexWhere((r) => r.id == cursor);
      if (index < 0) {
        throw const AppException('Danh sách đã thay đổi. Vui lòng tải lại.');
      }
      start = index + 1;
    }
    final items = reviews.skip(start).take(pageSize).toList();
    return ReviewPage(
      items: items,
      totalCount: reviews.length,
      nextCursor: start + items.length < reviews.length ? items.last.id : null,
      isDemo: true,
    );
  }
}
