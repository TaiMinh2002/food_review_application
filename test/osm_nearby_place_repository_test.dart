import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/places/data/osm_place_mapper.dart';
import 'package:food_review/features/places/data/overpass_nearby_place_repository.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const market = GeoPoint(20.9859, 105.7938);

http.Response jsonResponse(Object value) => http.Response.bytes(
  utf8.encode(jsonEncode(value)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, Object?> element({
  String type = 'node',
  int id = 1,
  double lat = 20.986,
  double lon = 105.794,
  Map<String, String> tags = const {'name': 'Quán ăn', 'amenity': 'restaurant'},
}) => {
  'type': type,
  'id': id,
  if (type == 'node') 'lat': lat,
  if (type == 'node') 'lon': lon,
  if (type != 'node') 'center': {'lat': lat, 'lon': lon},
  'tags': tags,
};

void main() {
  test('maps OSM IDs, centroids and only explicitly sourced values', () {
    final place = OsmPlaceMapper.fromElement(
      element(
        type: 'way',
        id: 42,
        tags: {
          'name': 'Coffee Shop',
          'name:vi': 'Cà phê Nhà',
          'amenity': 'cafe',
          'addr:housenumber': '2',
          'addr:street': 'Phùng Khoang',
        },
      ),
    )!;
    expect(place.id, 'osm_way_42');
    expect(place.name, 'Cà phê Nhà');
    expect(place.category, 'Cà phê');
    expect(place.address, '2, Phùng Khoang');
    expect(place.imageUrls, isEmpty);
    expect(place.menuItems, isEmpty);
    expect(place.reviewCount, 0);
    expect(place.isDemo, false);
  });

  test('rejects malformed, unnamed and unsupported OSM elements', () {
    expect(OsmPlaceMapper.fromElement(element(id: -1)), isNull);
    expect(
      OsmPlaceMapper.fromElement(
        element(tags: {'name': 'Chợ', 'amenity': 'marketplace'}),
      ),
      isNull,
    );
    expect(
      OsmPlaceMapper.fromElement(element(tags: {'amenity': 'restaurant'})),
      isNull,
    );
    expect(OsmPlaceMapper.fromElement(element(lat: 100)), isNull);
  });

  test('queries five kilometres, filters distance and reuses cache', () async {
    var calls = 0;
    String? query;
    final client = MockClient((request) async {
      calls++;
      query = request.bodyFields['data'];
      return jsonResponse({
        'elements': [
          element(id: 1),
          element(id: 1),
          element(id: 2, lat: 21.1),
          element(type: 'relation', id: 3, lat: 20.987),
        ],
      });
    });
    addTearDown(client.close);
    final source = OverpassNearbyPlaceRepository(client: client);
    final first = await source.findNearby(market);
    final second = await source.findNearby(market);
    expect(first.map((place) => place.id), ['osm_node_1', 'osm_relation_3']);
    expect(second, same(first));
    expect(calls, 1);
    expect(query, contains('around:5100,20.9859,105.7938'));
  });

  test('shares an in-flight request without returning partial data', () async {
    final pending = Completer<http.Response>();
    var calls = 0;
    final client = MockClient((_) {
      calls++;
      return pending.future;
    });
    addTearDown(client.close);
    final source = OverpassNearbyPlaceRepository(client: client);
    final first = source.findNearby(market);
    final second = source.findNearby(market);
    pending.complete(
      jsonResponse({
        'elements': [element()],
      }),
    );
    expect(await first, hasLength(1));
    expect(await second, hasLength(1));
    expect(calls, 1);
  });

  test('service failure is retryable and never replaced by demo', () async {
    var calls = 0;
    var currentTime = DateTime.utc(2026, 10, 22);
    final client = MockClient((_) async {
      calls++;
      return calls == 1
          ? http.Response('busy', 429)
          : jsonResponse({'elements': []});
    });
    addTearDown(client.close);
    final source = OverpassNearbyPlaceRepository(
      client: client,
      now: () => currentTime,
    );
    await expectLater(source.findNearby(market), throwsA(isA<AppException>()));
    await expectLater(source.findNearby(market), throwsA(isA<AppException>()));
    expect(calls, 1);
    currentTime = currentTime.add(const Duration(minutes: 1));
    expect(await source.findNearby(market), isEmpty);
    expect(calls, 2);
  });

  test('rejects incomplete Overpass responses and invalid radius', () async {
    final client = MockClient(
      (_) async => jsonResponse({'elements': [], 'remark': 'runtime error'}),
    );
    addTearDown(client.close);
    final source = OverpassNearbyPlaceRepository(client: client);
    await expectLater(source.findNearby(market), throwsA(isA<AppException>()));
    expect(
      () => source.findNearby(market, radiusMeters: 6000),
      throwsArgumentError,
    );
  });
}
