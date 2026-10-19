import '../../../core/errors/app_exception.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';

/// Preview fixtures, never submitted reviews or verified customer claims.
class DemoReviewRepository implements ReviewRepository {
  static final _reviews = [
    Review(
      id: 'review-linh-demo',
      placeId: 'pho-demo',
      userId: 'linh-demo',
      authorName: 'Hoàng Linh',
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
      rating: 4,
      content: 'Nhận xét minh họa: thích hương thơm của hành hoa và nước dùng. Nội dung được tạo để xem thử giao diện đánh giá, không xác minh trải nghiệm tại quán.',
      createdAt: DateTime.utc(2026, 10, 12),
      isDemo: true,
    ),
  ];

  @override
  Stream<List<Review>> watchForPlace(String placeId, {int limit = 20}) {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    return Stream.value(
      List.unmodifiable(
        _reviews.where((review) => review.placeId == placeId).take(limit),
      ),
    );
  }

  @override
  Future<void> create(Review review) async => throw const AppException(
    'Đăng đánh giá chưa được hỗ trợ trong bản demo.',
  );
}
