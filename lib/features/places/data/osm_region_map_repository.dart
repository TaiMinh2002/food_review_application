import '../../../core/errors/app_exception.dart';
import '../domain/place_map_repository.dart';
import '../domain/place_search.dart';
import 'osm_region_place_repository.dart';

/// Map capability backed by the bundled OSM region and a 5 km circle.
class OsmRegionMapRepository implements PlaceMapRepository {
  const OsmRegionMapRepository(this.region);
  final OsmRegionPlaceRepository region;

  @override
  Future<PlaceMapResult> findInViewport(
    MapViewport viewport, {
    required PlaceSearchRequest filters,
    GeoPoint? near,
    int limit = 50,
  }) async {
    if (limit < 1 || limit > 200) throw ArgumentError.value(limit, 'limit');
    if (filters.minRating != null ||
        filters.minPrice != null ||
        filters.maxPrice != null ||
        filters.sort != PlaceSearchSort.relevance) {
      throw const AppException(
        'Chưa có dữ liệu đánh giá hoặc giá để áp dụng bộ lọc này.',
      );
    }
    final center =
        near ??
        GeoPoint(
          (viewport.south + viewport.north) / 2,
          (viewport.west + viewport.east) / 2,
        );
    final nearby = await region.findNearby(center, radiusMeters: 5000);
    final query = normalizePlaceSearchText(filters.query);
    final matching = nearby.where((place) {
      final point = GeoPoint(place.latitude, place.longitude);
      return viewport.contains(point) &&
          (query.isEmpty ||
              normalizePlaceSearchText(place.name).contains(query)) &&
          (filters.categoryScope == null ||
              place.category == filters.categoryScope) &&
          (filters.categories.isEmpty ||
              filters.categories.contains(place.category)) &&
          (filters.amenities.isEmpty ||
              filters.amenities.every(place.amenities.contains));
    }).toList();
    return PlaceMapResult(
      places: matching.take(limit).toList(),
      hasMore: matching.length > limit,
    );
  }
}
