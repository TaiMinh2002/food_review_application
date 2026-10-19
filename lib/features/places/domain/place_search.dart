import 'place.dart';

enum PlaceSearchSort {
  relevance('Liên quan nhất'),
  rating('Đánh giá cao nhất'),
  reviews('Nhiều đánh giá nhất'),
  price('Giá thấp đến cao');

  const PlaceSearchSort(this.label);
  final String label;
  static PlaceSearchSort parse(String? value) =>
      values.where((sort) => sort.name == value).firstOrNull ?? relevance;
}

class PlaceSearchRequest {
  PlaceSearchRequest({
    this.query = '',
    Set<String> categories = const {},
    this.sort = PlaceSearchSort.relevance,
    this.minRating,
    this.minPrice,
    this.maxPrice,
    Set<String> amenities = const {},
  }) : categories = Set.unmodifiable(categories),
       amenities = Set.unmodifiable(amenities);
  final String query;
  final Set<String> categories, amenities;
  final PlaceSearchSort sort;
  final double? minRating;
  final int? minPrice, maxPrice;

  factory PlaceSearchRequest.fromUri(Uri uri) {
    final params = uri.queryParameters;
    int? price(String key) {
      final value = int.tryParse(params[key] ?? '');
      return value != null && value >= 0 ? value : null;
    }

    final min = price('minPrice'), max = price('maxPrice');
    final validRange = min == null || max == null || min <= max;
    final rating = double.tryParse(params['rating'] ?? '');
    return PlaceSearchRequest(
      query: params['q'] ?? '',
      categories: (uri.queryParametersAll['category'] ?? [])
          .where((item) => item.isNotEmpty)
          .toSet(),
      amenities: (uri.queryParametersAll['amenity'] ?? [])
          .where((item) => item.isNotEmpty)
          .toSet(),
      sort: PlaceSearchSort.parse(params['sort']),
      minRating: rating != null && rating > 0 && rating <= 5 ? rating : null,
      minPrice: validRange ? min : null,
      maxPrice: validRange ? max : null,
    );
  }

  PlaceSearchRequest copyWith({
    String? query,
    Set<String>? categories,
    PlaceSearchSort? sort,
    double? minRating,
    bool clearRating = false,
    int? minPrice,
    int? maxPrice,
    bool clearPrice = false,
    Set<String>? amenities,
  }) => PlaceSearchRequest(
    query: query ?? this.query,
    categories: categories ?? this.categories,
    sort: sort ?? this.sort,
    minRating: clearRating ? null : minRating ?? this.minRating,
    minPrice: minPrice ?? (clearPrice ? null : this.minPrice),
    maxPrice: maxPrice ?? (clearPrice ? null : this.maxPrice),
    amenities: amenities ?? this.amenities,
  );

  int get activeFilterCount =>
      categories.length +
      amenities.length +
      (minRating == null ? 0 : 1) +
      (minPrice == null && maxPrice == null ? 0 : 1) +
      (sort == PlaceSearchSort.relevance ? 0 : 1);

  Map<String, dynamic> get queryParameters => {
    if (query.trim().isNotEmpty) 'q': query.trim(),
    if (categories.isNotEmpty) 'category': categories.toList()..sort(),
    if (amenities.isNotEmpty) 'amenity': amenities.toList()..sort(),
    if (sort != PlaceSearchSort.relevance) 'sort': sort.name,
    if (minRating != null) 'rating': '$minRating',
    if (minPrice != null) 'minPrice': '$minPrice',
    if (maxPrice != null) 'maxPrice': '$maxPrice',
  };

  @override
  bool operator ==(Object other) =>
      other is PlaceSearchRequest &&
      query == other.query &&
      sort == other.sort &&
      minRating == other.minRating &&
      minPrice == other.minPrice &&
      maxPrice == other.maxPrice &&
      categories.length == other.categories.length &&
      categories.containsAll(other.categories) &&
      amenities.length == other.amenities.length &&
      amenities.containsAll(other.amenities);
  @override
  int get hashCode => Object.hash(
    query,
    sort,
    minRating,
    minPrice,
    maxPrice,
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(amenities),
  );
}

class PlaceSearchPage {
  PlaceSearchPage({
    required List<Place> items,
    List<String> categories = const [],
    List<String> amenities = const [],
    this.nextCursor,
    this.totalCount,
    this.isDemo = false,
  }) : items = List.unmodifiable(items),
       categories = List.unmodifiable(categories),
       amenities = List.unmodifiable(amenities);
  final List<Place> items;
  final List<String> categories, amenities;
  final String? nextCursor;
  final int? totalCount;
  final bool isDemo;
}

/// Supports precomposed and decomposed Vietnamese input without a dependency.
String normalizePlaceSearchText(String text) {
  var result = text.toLowerCase();
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final group in groups.entries) {
    result = result.replaceAll(RegExp('[${group.value}]'), group.key);
  }
  return result
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
