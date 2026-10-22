import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/places/data/osm_region_map_repository.dart';
import 'package:food_review/features/places/data/osm_region_place_repository.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';
import 'package:food_review/features/places/domain/place_search.dart';

const market = GeoPoint(20.9859, 105.7938);
const viewport = MapViewport(
  south: 20.93,
  west: 105.74,
  north: 21.04,
  east: 105.85,
);

void main() {
  test(
    'bundled OSM extract covers Phùng Khoang with true 5 km results',
    () async {
      final region = OsmRegionPlaceRepository(
        () => File('assets/osm/hanoi_urban_places.json').readAsString(),
      );
      final nearby = await region.findNearby(market);
      expect(nearby.length, 556);
      expect(nearby.every((place) => place.id.startsWith('osm_')), isTrue);
      expect(nearby.every((place) => !place.isDemo), isTrue);
      expect(
        nearby.every(
          (place) =>
              market.distanceTo(GeoPoint(place.latitude, place.longitude)) <=
              5000,
        ),
        isTrue,
      );
      expect(await region.sourceTime(), DateTime.utc(2026, 10, 21, 20, 21, 46));
      final north = await region.findNearby(const GeoPoint(21.0039, 105.7938));
      final east = await region.findNearby(const GeoPoint(20.9859, 105.8138));
      expect(north, hasLength(936));
      expect(east, hasLength(839));
      expect(
        north.map((place) => place.id).toSet(),
        isNot(equals(nearby.map((place) => place.id).toSet())),
      );

      final map = OsmRegionMapRepository(region);
      final result = await map.findInViewport(
        viewport,
        filters: PlaceSearchRequest(),
      );
      expect(result.places, hasLength(50));
      expect(result.hasMore, isTrue);
      expect(result.isDemo, isFalse);
      expect(
        result.places.every(
          (place) =>
              viewport.contains(GeoPoint(place.latitude, place.longitude)),
        ),
        isTrue,
      );
    },
  );

  test(
    'map search uses OSM names and rejects unavailable rating filters',
    () async {
      final region = OsmRegionPlaceRepository(
        () => File('assets/osm/hanoi_urban_places.json').readAsString(),
      );
      final map = OsmRegionMapRepository(region);
      final coffee = await map.findInViewport(
        viewport,
        filters: PlaceSearchRequest(query: 'ca phe'),
        limit: 200,
      );
      expect(coffee.places, isNotEmpty);
      expect(
        coffee.places.every(
          (place) => normalizePlaceSearchText(place.name).contains('ca phe'),
        ),
        isTrue,
      );
      await expectLater(
        map.findInViewport(
          viewport,
          filters: PlaceSearchRequest(minRating: 4.5),
        ),
        throwsA(isA<AppException>()),
      );
    },
  );
}
