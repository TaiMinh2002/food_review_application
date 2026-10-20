import 'dart:async';

import '../../../core/errors/app_exception.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import '../domain/review_feed_repository.dart';
import '../domain/user_review_repository.dart';

/// Preview fixtures, never submitted reviews or verified customer claims.
class DemoReviewRepository
    implements
        ReviewRepository,
        ReviewFeedRepository,
        ReviewMediaRepository,
        ReviewManagementRepository,
        UserReviewRepository {
  DemoReviewRepository({List<Review>? data})
    : _data = List<Review>.from(data ?? _reviews);
  final List<Review> _data;
  final _changes = StreamController<String>.broadcast(sync: true);
  void dispose() => _changes.close();

  @override
  Stream<void> watchUserReviewChanges(String userId) =>
      _changes.stream.where((id) => id == userId).map((_) {});

  @override
  Future<UserReviewSummary> getUserReviewSummary(String userId) async {
    final owned = _data.where((r) => r.userId == userId).toList();
    return UserReviewSummary(
      total: owned.length,
      withPhotos: owned.where((r) => r.imageUrls.isNotEmpty).length,
      edited: owned.where((r) => r.updatedAt != null).length,
      isDemo: true,
    );
  }

  @override
  Future<ReviewPage> getUserReviews(
    String userId, {
    required UserReviewFilter filter,
    String? cursor,
    int pageSize = 10,
  }) async {
    if (pageSize < 1 || pageSize > 50) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
    final owned =
        _data
            .where(
              (r) =>
                  r.userId == userId &&
                  switch (filter) {
                    UserReviewFilter.all => true,
                    UserReviewFilter.withPhotos => r.imageUrls.isNotEmpty,
                    UserReviewFilter.edited => r.updatedAt != null,
                  },
            )
            .toList()
          ..sort((a, b) {
            final date = b.createdAt.compareTo(a.createdAt);
            return date == 0 ? a.id.compareTo(b.id) : date;
          });
    var start = 0;
    if (cursor != null) {
      final index = owned.indexWhere((r) => r.id == cursor);
      if (index < 0) {
        throw const AppException('Danh sách đã thay đổi. Vui lòng tải lại.');
      }
      start = index + 1;
    }
    final items = owned.skip(start).take(pageSize).toList();
    return ReviewPage(
      items: items,
      totalCount: owned.length,
      isDemo: true,
      nextCursor: start + items.length < owned.length ? items.last.id : null,
    );
  }

  @override
  Future<Review?> getReview(String placeId, String reviewId) async => _data
      .where((review) => review.placeId == placeId && review.id == reviewId)
      .firstOrNull;
  static final _reviews = [
    Review(
      id: 'review-linh-demo',
      placeId: 'pho-demo',
      userId: 'linh-demo',
      authorName: 'Hoàng Linh',
      dishes: ['Phở Bò Tái Lăn', 'Quẩy Giòn'],
      rating: 5,
      content: 'Nhận xét minh họa: nước dùng thanh, thịt bò mềm và quẩy giòn. Một bát phở nóng cùng rau thơm là gợi ý dễ chịu cho bữa sáng.',
      createdAt: DateTime.utc(2026, 10, 18),
      isDemo: true,
      imageUrls: [
        'assets/images/demo/review_pho_1.jpg',
        'assets/images/demo/review_pho_2.jpg',
      ],
    ),
    Review(
      id: 'review-nam-demo',
      placeId: 'pho-demo',
      userId: 'nam-demo',
      authorName: 'Trần Nhật Nam',
      dishes: ['Phở Tái Nạm Gầu'],
      rating: 4,
      content: 'Nhận xét minh họa: thích hương thơm của hành hoa và nước dùng. Nội dung được tạo để xem thử giao diện đánh giá, không xác minh trải nghiệm tại quán.',
      createdAt: DateTime.utc(2026, 10, 12),
      isDemo: true,
    ),
    Review(
      id: 'review-chau-demo',
      placeId: 'pho-demo',
      userId: 'chau-demo',
      authorName: 'Minh Châu',
      rating: 4,
      dishes: ['Phở Bò Chín Nạm'],
      content: 'Nhận xét minh họa: thịt bò mềm, nước dùng đậm đà. Chỗ ngồi có thể chật vào giờ cao điểm. Đây là nội dung mẫu để xem thử giao diện, không xác minh trải nghiệm thực tế.',
      createdAt: DateTime.utc(2026, 10, 5),
      isDemo: true,
      imageUrls: ['assets/images/demo/dish_chin.jpg'],
    ),
    Review(
      id: 'review-hai-demo',
      placeId: 'pho-demo',
      userId: 'hai-demo',
      authorName: 'Đặng Hải',
      rating: 5,
      dishes: ['Phở Bò Tái Lăn'],
      content: 'Nhận xét minh họa: một bát phở nóng cùng rau thơm cho bữa sáng. Nội dung dùng để trình bày đánh giá ngắn, không phải lời nhận xét đã xác minh.',
      createdAt: DateTime.utc(2026, 9, 28),
      isDemo: true,
    ),
  ];

  @override
  Stream<List<Review>> watchForPlace(String placeId, {int limit = 20}) {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    return Stream.value(
      List.unmodifiable(
        _data.where((review) => review.placeId == placeId).take(limit),
      ),
    );
  }

  @override
  Future<ReviewSummary> getSummary(String placeId) async {
    final reviews = _data.where((review) => review.placeId == placeId).toList();
    return ReviewSummary(
      totalCount: reviews.length,
      averageRating: reviews.isEmpty
          ? null
          : reviews.fold(0, (sum, r) => sum + r.rating) / reviews.length,
      starCounts: {
        for (var star = 1; star <= 5; star++)
          star: reviews.where((r) => r.rating == star).length,
      },
      withPhotosCount: reviews.where((r) => r.imageUrls.isNotEmpty).length,
      isDemo: true,
    );
  }

  @override
  Future<ReviewPage> getReviews(
    String placeId, {
    required ReviewFilters filters,
    String? cursor,
    int pageSize = 10,
  }) async {
    if (pageSize < 1 || pageSize > 50) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const AppException(
        'Không tải được trang đánh giá. Vui lòng tải lại danh sách.',
      );
    }
    final reviews = _data
        .where(
          (r) =>
              r.placeId == placeId &&
              (filters.rating == null || r.rating == filters.rating) &&
              (!filters.withPhotos || r.imageUrls.isNotEmpty),
        )
        .toList();
    reviews.sort((a, b) {
      final order = switch (filters.sort) {
        ReviewSort.newest => b.createdAt.compareTo(a.createdAt),
        ReviewSort.oldest => a.createdAt.compareTo(b.createdAt),
        ReviewSort.ratingHigh => b.rating.compareTo(a.rating),
        ReviewSort.ratingLow => a.rating.compareTo(b.rating),
      };
      return order != 0 ? order : a.id.compareTo(b.id);
    });
    final items = reviews.skip(offset).take(pageSize).toList();
    return ReviewPage(
      items: items,
      totalCount: reviews.length,
      nextCursor: offset + items.length < reviews.length
          ? '${offset + items.length}'
          : null,
      isDemo: true,
    );
  }

  @override
  Future<void> create(Review review) async {
    if (review.content.trim().length < 10) {
      throw const AppException('Nội dung đánh giá cần ít nhất 10 ký tự.');
    }
    if (_data.any((item) => item.id == review.id)) {
      throw const AppException('Đánh giá này đã được gửi.');
    }
    _data.insert(0, review);
    _changes.add(review.userId);
  }

  @override
  Stream<List<Review>> watchForUser(String userId) => Stream.value(
    List.unmodifiable(_data.where((review) => review.userId == userId)),
  );

  @override
  Future<void> update(Review review) async {
    final index = _data.indexWhere(
      (item) => item.placeId == review.placeId && item.id == review.id,
    );
    if (index < 0) {
      throw const AppException('Không tìm thấy đánh giá để cập nhật.');
    }
    if (_data[index].userId != review.userId) {
      throw const AppException('Bạn không có quyền sửa đánh giá này.');
    }
    if (review.content.trim().length < 10) {
      throw const AppException('Nội dung đánh giá cần ít nhất 10 ký tự.');
    }
    _data[index] = review;
    _changes.add(review.userId);
  }

  @override
  Future<void> delete({
    required String userId,
    required String placeId,
    required String reviewId,
  }) async {
    final index = _data.indexWhere(
      (item) =>
          item.userId == userId &&
          item.placeId == placeId &&
          item.id == reviewId,
    );
    if (index < 0) {
      throw const AppException('Bạn không có quyền xóa đánh giá này.');
    }
    _data.removeAt(index);
    _changes.add(userId);
  }
}
