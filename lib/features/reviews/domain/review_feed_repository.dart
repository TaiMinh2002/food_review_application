import 'review.dart';

enum ReviewSort {
  newest('Mới nhất'),
  oldest('Cũ nhất'),
  ratingHigh('Điểm cao nhất'),
  ratingLow('Điểm thấp nhất');

  const ReviewSort(this.label);
  final String label;
}

class ReviewFilters {
  const ReviewFilters({
    this.rating,
    this.withPhotos = false,
    this.sort = ReviewSort.newest,
  });
  final int? rating;
  final bool withPhotos;
  final ReviewSort sort;
  factory ReviewFilters.fromUri(Uri uri) {
    final rating = int.tryParse(uri.queryParameters['rating'] ?? '');
    return ReviewFilters(
      rating: rating != null && rating >= 1 && rating <= 5 ? rating : null,
      withPhotos: uri.queryParameters['photos'] == '1',
      sort:
          ReviewSort.values
              .where((s) => s.name == uri.queryParameters['sort'])
              .firstOrNull ??
          ReviewSort.newest,
    );
  }
  ReviewFilters copyWith({
    int? rating,
    bool clearRating = false,
    bool? withPhotos,
    ReviewSort? sort,
  }) => ReviewFilters(
    rating: clearRating ? null : rating ?? this.rating,
    withPhotos: withPhotos ?? this.withPhotos,
    sort: sort ?? this.sort,
  );
  int get activeCount => (rating == null ? 0 : 1) + (withPhotos ? 1 : 0);
  Map<String, String> get queryParameters => {
    if (rating != null) 'rating': '$rating',
    if (withPhotos) 'photos': '1',
    if (sort != ReviewSort.newest) 'sort': sort.name,
  };
  @override
  bool operator ==(Object other) =>
      other is ReviewFilters &&
      rating == other.rating &&
      withPhotos == other.withPhotos &&
      sort == other.sort;
  @override
  int get hashCode => Object.hash(rating, withPhotos, sort);
}

class ReviewSummary {
  ReviewSummary({
    required this.totalCount,
    this.averageRating,
    Map<int, int>? starCounts,
    this.withPhotosCount,
    this.isDemo = false,
  }) : starCounts = starCounts == null ? null : Map.unmodifiable(starCounts) {
    if (totalCount < 0 ||
        (averageRating != null &&
            (!averageRating!.isFinite ||
                averageRating! < 1 ||
                averageRating! > 5)) ||
        (withPhotosCount != null &&
            (withPhotosCount! < 0 || withPhotosCount! > totalCount))) {
      throw ArgumentError('Invalid review summary');
    }
    if (starCounts != null &&
        (starCounts.entries.any(
              (entry) => entry.key < 1 || entry.key > 5 || entry.value < 0,
            ) ||
            starCounts.values.fold(0, (sum, value) => sum + value) !=
                totalCount)) {
      throw ArgumentError(
        'Star distribution must represent the entire summary',
      );
    }
  }
  final int totalCount;
  final double? averageRating;
  final Map<int, int>? starCounts;
  final int? withPhotosCount;
  final bool isDemo;
  int? get highRatingPercent => totalCount == 0 || starCounts == null
      ? null
      : ((((starCounts![4] ?? 0) + (starCounts![5] ?? 0)) / totalCount) * 100)
            .round();
}

class ReviewPage {
  ReviewPage({
    required List<Review> items,
    this.nextCursor,
    this.totalCount,
    this.isDemo = false,
  }) : items = List.unmodifiable(items);
  final List<Review> items;
  final String? nextCursor;
  final int? totalCount;
  final bool isDemo;
}

/// Separate read capability so existing preview and write integrations keep working.
/// Real implementations query/filter/order/limit on the server. Summary describes
/// ALL reviews of this place, never just the loaded or filtered page.
abstract interface class ReviewFeedRepository {
  Future<ReviewSummary> getSummary(String placeId);
  Future<ReviewPage> getReviews(
    String placeId, {
    required ReviewFilters filters,
    String? cursor,
    int pageSize = 10,
  });
}
