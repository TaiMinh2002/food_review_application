import 'place.dart';
import 'place_map_repository.dart';

/// Finds actual places around a chosen point, independent of the map tiles.
/// Implementations must never silently substitute illustrative places.
abstract interface class NearbyPlaceRepository {
  Future<List<Place>> findNearby(GeoPoint center, {int radiusMeters = 5000});
}
