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

    final scope = PlaceCategory.byId(request.categoryScope);
    if (request.categoryScope != null && scope == null) {
      throw const AppException('Danh mục không tồn tại.');
    }
    if (scope != null && !scope.isOsmSupported) {
      throw const AppException(
        'Nguồn OSM hiện chưa có dữ liệu phân loại món ăn cho danh mục này.',
        code: 'unsupported_category',
      );
    }
    final nearby = await _places.findNearby(_center, radiusMeters: 5000);
    final scoped = nearby.where(
      (place) => scope == null || scope.contains(place),
    );
    final query = normalizePlaceSearchText(request.query);
    final categories = <String>{};
    for (final place in scoped) {
      categories.add(place.category);
      categories.addAll(place.foodCategories);
    }
    final filtered = scoped
        .where((place) {
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
