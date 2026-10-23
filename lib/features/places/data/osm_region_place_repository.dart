import 'dart:convert';
import 'dart:math' as math;

import '../../../core/errors/app_exception.dart';
import '../domain/nearby_place_repository.dart';
import '../domain/place.dart';
import '../domain/place_map_repository.dart';
import '../domain/place_repository.dart';
import 'osm_place_mapper.dart';

/// Offline OSM region package. A small grid index is built once after loading.
/// The JSON comes from tools/build_osm_region.py, not a Firestore catalog scan.
class OsmRegionPlaceRepository
    implements NearbyPlaceRepository, PlaceRepository {
  OsmRegionPlaceRepository(this.loadPackage);

  final Future<String> Function() loadPackage;
  Future<_RegionIndex>? _pending;

  Future<_RegionIndex> _index() =>
      _pending ??= _load().catchError((Object error) {
        _pending = null;
        throw error;
      });

  Future<_RegionIndex> _load() async {
    try {
      final data = jsonDecode(await loadPackage());
      if (data is! Map<String, dynamic> || data['schemaVersion'] != 1) {
        throw const FormatException('Invalid OSM package schema');
      }
      final bounds = _Bounds.parse(data['supportedBounds']);
      final extractBounds = _Bounds.parse(data['extractBounds']);
      if (bounds == null ||
          extractBounds == null ||
          !extractBounds.covers(bounds)) {
        throw const FormatException('Invalid OSM package bounds');
      }
      final sourceTime = DateTime.tryParse(
        data['sourceTimestamp']?.toString() ?? '',
      );
      final checksum = data['sourceSha256'];
      if (sourceTime == null ||
          checksum is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(checksum) ||
          data['license'] != 'ODbL-1.0' ||
          data['attribution'] != '© OpenStreetMap contributors') {
        throw const FormatException('Invalid OSM package provenance');
      }
      final raw = data['elements'];
      if (raw is! List) throw const FormatException('Invalid OSM places');
      final byId = <String, Place>{};
      final grid = <(int, int), List<Place>>{};
      for (final item in raw) {
        final place = OsmPlaceMapper.fromElement(item);
        if (place == null || byId.containsKey(place.id)) continue;
        final point = GeoPoint(place.latitude, place.longitude);
        if (!extractBounds.contains(point)) continue;
        byId[place.id] = place;
        grid.putIfAbsent(_cell(point), () => []).add(place);
      }
      if (byId.isEmpty) throw const FormatException('Empty OSM package');
      return _RegionIndex(
        supportedBounds: bounds,
        placesById: Map.unmodifiable(byId),
        grid: Map.unmodifiable(grid),
        sourceTime: sourceTime,
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException('Không đọc được dữ liệu quán của khu vực này.');
    }
  }

  @override
  Future<List<Place>> findNearby(
    GeoPoint center, {
    int radiusMeters = 5000,
  }) async {
    if (!center.isValid || radiusMeters < 1 || radiusMeters > 5000) {
      throw ArgumentError('Invalid center or radius');
    }
    final index = await _index();
    if (!index.supportedBounds.contains(center)) {
      throw const AppException('Khu vực này chưa có dữ liệu quán ngoại tuyến.');
    }
    final latDegrees = radiusMeters / 111_000;
    final lonDegrees =
        radiusMeters /
        (111_000 * math.cos(center.latitude * math.pi / 180).abs());
    final south = ((center.latitude - latDegrees) / _cellDegrees).floor();
    final north = ((center.latitude + latDegrees) / _cellDegrees).floor();
    final west = ((center.longitude - lonDegrees) / _cellDegrees).floor();
    final east = ((center.longitude + lonDegrees) / _cellDegrees).floor();
    final results = <Place>[];
    for (var lat = south; lat <= north; lat++) {
      for (var lon = west; lon <= east; lon++) {
        for (final place in index.grid[(lat, lon)] ?? const <Place>[]) {
          if (center.distanceTo(GeoPoint(place.latitude, place.longitude)) <=
              radiusMeters) {
            results.add(place);
          }
        }
      }
    }
    results.sort((a, b) {
      final order = center
          .distanceTo(GeoPoint(a.latitude, a.longitude))
          .compareTo(center.distanceTo(GeoPoint(b.latitude, b.longitude)));
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return List.unmodifiable(results);
  }

  Future<Place?> getById(String id) async => (await _index()).placesById[id];

  @override
  Future<Place?> getPlace(String id) => getById(id);

  @override
  Future<List<Place>> fetchPlaces() async =>
      (await _index()).placesById.values.toList();

  Future<DateTime> sourceTime() async => (await _index()).sourceTime;
}

const _cellDegrees = 0.01;

(int, int) _cell(GeoPoint point) => (
  (point.latitude / _cellDegrees).floor(),
  (point.longitude / _cellDegrees).floor(),
);

class _RegionIndex {
  const _RegionIndex({
    required this.supportedBounds,
    required this.placesById,
    required this.grid,
    required this.sourceTime,
  });
  final _Bounds supportedBounds;
  final Map<String, Place> placesById;
  final Map<(int, int), List<Place>> grid;
  final DateTime sourceTime;
}

class _Bounds {
  const _Bounds(this.south, this.west, this.north, this.east);
  final double south, west, north, east;

  static _Bounds? parse(Object? value) {
    if (value is! Map) return null;
    final south = value['south'];
    final west = value['west'];
    final north = value['north'];
    final east = value['east'];
    if (south is! num || west is! num || north is! num || east is! num) {
      return null;
    }
    final bounds = _Bounds(
      south.toDouble(),
      west.toDouble(),
      north.toDouble(),
      east.toDouble(),
    );
    return bounds.south < bounds.north &&
            bounds.west < bounds.east &&
            GeoPoint(bounds.south, bounds.west).isValid &&
            GeoPoint(bounds.north, bounds.east).isValid
        ? bounds
        : null;
  }

  bool contains(GeoPoint point) =>
      point.latitude >= south &&
      point.latitude <= north &&
      point.longitude >= west &&
      point.longitude <= east;

  bool covers(_Bounds other) =>
      south <= other.south &&
      west <= other.west &&
      north >= other.north &&
      east >= other.east;
}
