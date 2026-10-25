import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/places/data/osm_region_place_repository.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';

const market = GeoPoint(20.9859, 105.7938);

Map<String, Object?> point(int id, double latitude, double longitude) => {
  'type': 'node',
  'id': id,
  'lat': latitude,
  'lon': longitude,
  'tags': {'amenity': 'restaurant', 'name': 'Quán $id'},
};

String packageJson(List<Object?> elements) => jsonEncode({
  'schemaVersion': 1,
  'regionId': 'hanoi-urban',
  'sourceUrl': 'https://download.geofabrik.de/asia/vietnam-latest.osm.pbf',
  'sourceTimestamp': '2026-10-21T20:21:46Z',
  'sourceSha256': List.filled(64, 'a').join(),
  'license': 'ODbL-1.0',
  'attribution': '© OpenStreetMap contributors',
  'supportedBounds': {
    'south': 20.88,
    'west': 105.66,
    'north': 21.12,
    'east': 105.98,
  },
  'extractBounds': {
    'south': 20.82,
    'west': 105.60,
    'north': 21.18,
    'east': 106.04,
  },
  'elements': elements,
});

void main() {
  test(
    'five-kilometre query sorts actual OSM points and never returns outside',
    () async {
      var reads = 0;
      final source = OsmRegionPlaceRepository(() async {
        reads++;
        return packageJson([
          point(1, 20.986, 105.794),
          point(2, 21.02, 105.7938),
          point(3, 21.08, 105.7938),
          point(1, 20.986, 105.794),
        ]);
      });
      final first = await source.findNearby(market);
      expect(first.map((place) => place.id), ['osm_node_1', 'osm_node_2']);
      expect((await source.getById('osm_node_3'))?.name, 'Quán 3');
      expect(await source.sourceTime(), DateTime.utc(2026, 10, 21, 20, 21, 46));
      expect((await source.findNearby(market, radiusMeters: 500)).length, 1);
      expect(reads, 1);
    },
  );

  test('concurrent reads share one asset load', () async {
    final pending = Completer<String>();
    var reads = 0;
    final source = OsmRegionPlaceRepository(() {
      reads++;
      return pending.future;
    });
    final first = source.findNearby(market);
    final second = source.findNearby(market);
    pending.complete(packageJson([point(1, 20.986, 105.794)]));
    expect(await first, hasLength(1));
    expect(await second, hasLength(1));
    expect(reads, 1);
  });

  test(
    'unsupported center and invalid radius never fall back to demo',
    () async {
      final source = OsmRegionPlaceRepository(
        () async => packageJson([point(1, 20.986, 105.794)]),
      );
      await expectLater(
        source.findNearby(const GeoPoint(16.05, 108.22)),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        source.findNearby(market, radiusMeters: 35000),
        throwsArgumentError,
      );
    },
  );

  test('invalid package fails visibly and can be reloaded', () async {
    var reads = 0;
    final source = OsmRegionPlaceRepository(() async {
      reads++;
      return reads == 1 ? '{invalid' : packageJson([point(1, 20.986, 105.794)]);
    });
    await expectLater(source.findNearby(market), throwsA(isA<AppException>()));
    expect(await source.findNearby(market), hasLength(1));
    expect(reads, 2);
  });
}
