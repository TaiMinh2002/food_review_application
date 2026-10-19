enum PhotoCategory {
  food('Món ăn'),
  space('Không gian'),
  guests('Thực khách'),
  other('Ảnh khác');

  const PhotoCategory(this.label);
  final String label;
}

class GalleryPhoto {
  const GalleryPhoto({
    required this.url,
    required this.title,
    this.author,
    this.category = PhotoCategory.other,
    this.isDemo = false,
  });
  final String url, title;
  final String? author;
  final PhotoCategory category;
  final bool isDemo;
}

class GalleryCollection {
  GalleryCollection(List<GalleryPhoto> photos)
    : photos = List.unmodifiable(photos);
  final List<GalleryPhoto> photos;
  int safeIndex(int? requested) =>
      photos.isEmpty ? 0 : (requested ?? 0).clamp(0, photos.length - 1);
}

class GalleryRequest {
  const GalleryRequest({
    required this.placeId,
    this.fromReview = false,
    this.reviewId,
    this.index,
  });
  factory GalleryRequest.fromUri(String placeId, Uri uri) => GalleryRequest(
    placeId: placeId,
    fromReview: uri.queryParameters['source'] == 'review',
    reviewId: uri.queryParameters['reviewId'],
    index: uri.queryParameters.containsKey('index')
        ? int.tryParse(uri.queryParameters['index']!) ?? 0
        : null,
  );
  final String placeId;
  final bool fromReview;
  final String? reviewId;
  final int? index;
  @override
  bool operator ==(Object other) =>
      other is GalleryRequest &&
      placeId == other.placeId &&
      fromReview == other.fromReview &&
      reviewId == other.reviewId &&
      index == other.index;
  @override
  int get hashCode => Object.hash(placeId, fromReview, reviewId, index);
}
