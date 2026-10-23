import '../../../core/errors/app_exception.dart';
import '../domain/nearby_place_repository.dart';
import '../domain/place_category.dart';
import '../domain/place_map_repository.dart';
import '../domain/place_search.dart';
import '../domain/place_search_repository.dart';

/// Searches only the bounded OSM result set around the user's chosen center.
class OsmRegionSearchRepository implements PlaceSearchRepository {
  const OsmRegionSearchRepository(this._places, this._center);

  final NearbyPlaceRepository _places;
  final GeoPoint _center;

  @override
  Future<PlaceSearchPage> searchPlaces(
    PlaceSearchRequest request, {
    String? cursor,
    int pageSize = 20,
  }) async {
    if (pageSize < 1 || pageSize > 100) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
    if (request.sort != PlaceSearchSort.relevance ||
        request.minRating != null ||
        request.minPrice != null ||
        request.maxPrice != null ||
        request.amenities.isNotEmpty) {
      throw const AppException(
        'OSM chưa có dữ liệu đánh giá, giá hoặc tiện ích để áp dụng bộ lọc này.',
        code: 'unsupported_filter',
      );
    }

    final nearby = await _places.findNearby(_center, radiusMeters: 5000);
    final scope = PlaceCategory.byId(request.categoryScope);
    final query = normalizePlaceSearchText(request.query);
    final categories = <String>{};
    for (final place in nearby) {
      categories.add(place.category);
      categories.addAll(place.foodCategories);
    }
    final filtered = nearby
        .where((place) {
          if (scope != null && !scope.contains(place)) return false;
          if (request.categoryScope != null && scope == null) return false;
          if (request.categories.isNotEmpty &&
              !request.categories.any(
                (category) =>
                    category == place.category ||
                    place.foodCategories.contains(category),
              )) {
            return false;
          }
          if (query.isEmpty) return true;
          return normalizePlaceSearchText(
            [
              place.name,
              place.address,
              place.category,
              ...place.foodCategories,
            ].join(' '),
          ).contains(query);
        })
        .toList(growable: false);

    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0 || offset > filtered.length) {
      throw const AppException('Vị trí trang tìm kiếm không hợp lệ.');
    }
    final end = (offset + pageSize).clamp(0, filtered.length);
    return PlaceSearchPage(
      items: filtered.sublist(offset, end),
      categories: categories.toList()..sort(),
      totalCount: filtered.length,
      nextCursor: end < filtered.length ? '$end' : null,
    );
  }
}
