import 'package:food_review/features/reviews/domain/review.dart';

List<Review> ownedReviews({int count = 23, String userId = 'user-a'}) =>
    List.generate(
      count,
      (index) => Review(
        id: 'owned-$index',
        placeId: index.isEven ? 'pho-demo' : 'coffee-demo',
        userId: userId,
        authorName: 'Người thử nghiệm',
        title: 'Trải nghiệm $index',
        content: 'Nội dung minh họa: món ăn ngon, phục vụ thân thiện và không gian thoải mái.',
        rating: index.isEven ? 5 : 4,
        createdAt: DateTime.utc(2026, 10, 20 - index),
        updatedAt: index % 3 == 0 ? DateTime.utc(2026, 10, 20) : null,
        imageUrls: index.isEven ? ['assets/images/demo/review_pho_1.jpg'] : [],
        isDemo: true,
      ),
    );
