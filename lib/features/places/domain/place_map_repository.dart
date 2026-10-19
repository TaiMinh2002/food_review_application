import 'dart:math' as math;

import 'place.dart';
import 'place_search.dart';

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);
  final double latitude, longitude;
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;

  double distanceTo(GeoPoint other) {
    const radians = math.pi / 180;
    final lat = (other.latitude - latitude) * radians;
    final lon = (other.longitude - longitude) * radians;
    final a =
        math.pow(math.sin(lat / 2), 2) +
        math.cos(latitude * radians) *
            math.cos(other.latitude * radians) *
            math.pow(math.sin(lon / 2), 2);
    return 6371000 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }
}

class MapViewport {
  const MapViewport({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });
  final double south, west, north, east;
  bool contains(GeoPoint point) =>
      point.isValid &&
      point.latitude >= south &&
      point.latitude <= north &&
      (west <= east
          ? point.longitude >= west && point.longitude <= east
          : point.longitude >= west || point.longitude <= east);
}

class PlaceMapResult {
  PlaceMapResult({
    required List<Place> places,
    this.hasMore = false,
    this.isDemo = false,
  }) : places = List.unmodifiable(places);
  final List<Place> places;
  final bool hasMore, isDemo;
}

/// A bounded spatial query. Real implementations must apply bounds and limit
/// on the server, never download the full restaurant collection.
abstract interface class PlaceMapRepository {
  Future<PlaceMapResult> findInViewport(
    MapViewport viewport, {
    required PlaceSearchRequest filters,
    GeoPoint? near,
    int limit = 50,
  });
}

abstract interface class UserLocationRepository {
  /// One foreground fix, requested only by an explicit user action.
  Future<GeoPoint> locate();
  Future<bool> openSettings();
}

Uri walkingDirections(Place place) =>
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${place.latitude},${place.longitude}',
      'travelmode': 'walking',
    });
