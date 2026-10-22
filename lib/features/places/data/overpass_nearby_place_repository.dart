import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/errors/app_exception.dart';
import '../domain/nearby_place_repository.dart';
import '../domain/place.dart';
import '../domain/place_map_repository.dart';
import 'osm_place_mapper.dart';

/// Development-only source for measuring OSM coverage. Public Overpass is not
/// a production app backend; the release source will be a regional OSM extract.
class OverpassNearbyPlaceRepository implements NearbyPlaceRepository {
  OverpassNearbyPlaceRepository({
    required this.client,
    Uri? endpoint,
    DateTime Function()? now,
  }) : endpoint = endpoint ?? Uri.https('overpass-api.de', '/api/interpreter'),
       now = now ?? DateTime.now;

  final http.Client client;
  final Uri endpoint;
  final DateTime Function() now;
  final Map<String, ({DateTime fetchedAt, List<Place> items})> _cache = {};
  final Map<String, Future<List<Place>>> _pending = {};
  DateTime? _retryAfter;

  @override
  Future<List<Place>> findNearby(GeoPoint center, {int radiusMeters = 5000}) {
    if (!center.isValid || radiusMeters < 1 || radiusMeters > 5000) {
      throw ArgumentError('Invalid center or radius');
    }
    final key = '${center.latitude}:${center.longitude}:$radiusMeters';
    final cached = _cache[key];
    if (cached != null &&
        now().difference(cached.fetchedAt) < const Duration(minutes: 15)) {
      return Future.value(cached.items);
    }
    if (_retryAfter?.isAfter(now()) == true) {
      return Future.error(
        const AppException('Nguồn địa điểm đang bận. Vui lòng thử lại sau.'),
      );
    }
    return _pending[key] ??= _load(center, radiusMeters)
        .then((items) {
          _cache[key] = (fetchedAt: now(), items: items);
          return items;
        })
        .whenComplete(() {
          _pending.remove(key);
        });
  }

  Future<List<Place>> _load(GeoPoint center, int radiusMeters) async {
    // Overpass around matches geometry, while ways/relations display at their
    // center. Widen the query slightly and enforce the visible 5 km boundary.
    final queryRadius = radiusMeters + 100;
    final query =
        '[out:json][timeout:25];'
        'nwr["amenity"~"^(restaurant|cafe|fast_food|food_court)\$"]'
        '(around:$queryRadius,${center.latitude},${center.longitude});'
        'out center;';
    try {
      final response = await client
          .post(
            endpoint,
            headers: {'User-Agent': 'food-review-development/0.1'},
            body: {'data': query},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 429 || response.statusCode == 504) {
        _retryAfter = now().add(const Duration(minutes: 1));
        throw const AppException(
          'Nguồn địa điểm đang bận. Vui lòng thử lại sau.',
        );
      }
      if (response.statusCode != 200) {
        throw const AppException('Không tải được địa điểm quanh đây.');
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map || body['elements'] is! List) {
        throw const AppException('Dữ liệu địa điểm không hợp lệ.');
      }
      final elements = body['elements'] as List;
      if (elements.length > 10000 || body['remark'] != null) {
        throw const AppException('Dữ liệu địa điểm chưa đầy đủ.');
      }
      final byId = <String, Place>{};
      for (final element in elements) {
        final place = OsmPlaceMapper.fromElement(element);
        if (place == null) continue;
        if (center.distanceTo(GeoPoint(place.latitude, place.longitude)) >
            radiusMeters) {
          continue;
        }
        byId[place.id] = place;
      }
      final items = byId.values.toList()
        ..sort((a, b) {
          final distance = center
              .distanceTo(GeoPoint(a.latitude, a.longitude))
              .compareTo(center.distanceTo(GeoPoint(b.latitude, b.longitude)));
          return distance == 0 ? a.id.compareTo(b.id) : distance;
        });
      return List.unmodifiable(items);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        'Không kết nối được nguồn địa điểm. Kiểm tra mạng và thử lại.',
      );
    }
  }
}
