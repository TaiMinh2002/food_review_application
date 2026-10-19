class Review {
  Review({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.authorName = 'Thành viên',
    this.title,
    this.visitDate,
    this.companion,
    this.isDemo = false,
    List<String> imageUrls = const [],
    List<String> dishes = const [],
  }) : imageUrls = List.unmodifiable(imageUrls),
       dishes = List.unmodifiable(dishes) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Phải từ 1 đến 5');
    }
    if (content.trim().isEmpty) {
      throw ArgumentError.value(content, 'content', 'Không được để trống');
    }
  }

  final String authorName;
  final String? title;
  final DateTime? visitDate;
  final String? companion;
  final bool isDemo;
  final String id;
  final String placeId;
  final String userId;
  final int rating;
  final String content;
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<String> dishes;
}
