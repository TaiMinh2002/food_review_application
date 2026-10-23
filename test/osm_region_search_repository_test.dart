import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/places/data/osm_region_search_repository.dart';
import 'package:food_review/features/places/domain/nearby_place_repository.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';
import 'package:food_review/features/places/domain/place_search.dart';

const _center = GeoPoint(20.9859, 105.7938);
const _places = [
  Place(
    id: 'near',
    name: 'Quán Phở',
    description: '',
    address: 'Thanh Xuân',
    category: 'Nhà hàng',
    latitude: 20.986,
    longitude: 105.794,
  ),
  Place(
    id: 'cafe',
    name: 'Cafe Bờ Hồ',
    description: '',
    address: 'Hà Nội',
    category: 'Cà phê',
    latitude: 20.987,
    longitude: 105.795,
  ),
];

void main() {
  test(
    'searches the 5 km region with accent-insensitive text and pages',
    () async {
      final nearby = _Nearby(_places);
      final repository = OsmRegionSearchRepository(nearby, _center);
      final page = await repository.searchPlaces(
        PlaceSearchRequest(query: 'pho'),
        pageSize: 1,
      );

      expect(nearby.lastCenter, _center);
      expect(nearby.lastRadius, 5000);
      expect(page.items.map((place) => place.id), ['near']);
      expect(page.totalCount, 1);
      expect(page.nextCursor, isNull);
    },
  );

  test(
    'applies root and subtype filters before count and cursor paging',
    () async {
      final repository = OsmRegionSearchRepository(_Nearby(_places), _center);
      final page = await repository.searchPlaces(
        PlaceSearchRequest(categoryScope: 'ca-phe', categories: {'Cà phê'}),
      );

      expect(page.items.map((place) => place.id), ['cafe']);
      expect(page.totalCount, 1);
    },
  );

  test('rejects filters unsupported by the real OSM source', () async {
    final repository = OsmRegionSearchRepository(_Nearby(_places), _center);

    await expectLater(
      repository.searchPlaces(PlaceSearchRequest(minRating: 4)),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'unsupported_filter',
        ),
      ),
    );
    await expectLater(
      repository.searchPlaces(PlaceSearchRequest(sort: PlaceSearchSort.rating)),
      throwsA(isA<AppException>()),
    );
  });
}

class _Nearby implements NearbyPlaceRepository {
  _Nearby(this.places);
  final List<Place> places;
  GeoPoint? lastCenter;
  int? lastRadius;

  @override
  Future<List<Place>> findNearby(
    GeoPoint center, {
    int radiusMeters = 5000,
  }) async {
    lastCenter = center;
    lastRadius = radiusMeters;
    return places;
  }
}
