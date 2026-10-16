class Review {
  Review({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    required this.content,
    required this.createdAt,
    List<String> imageUrls = const [],
  }) : imageUrls = List.unmodifiable(imageUrls) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'Phải từ 1 đến 5');
    }
    if (content.trim().isEmpty) {
      throw ArgumentError.value(content, 'content', 'Không được để trống');
    }
  }

  final String id;
  final String placeId;
  final String userId;
  final int rating;
  final String content;
  final DateTime createdAt;
  final List<String> imageUrls;
}
