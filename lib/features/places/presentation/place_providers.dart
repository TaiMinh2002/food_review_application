import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_place_repository.dart';
import '../domain/place.dart';
import '../domain/place_repository.dart';
import '../domain/place_search.dart';
import '../domain/nearby_place_repository.dart';
import 'discovery_center.dart';
import 'map_controller.dart';

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => DemoPlaceRepository(),
);

final placesProvider = FutureProvider<List<Place>>(
  (ref) => ref.watch(placeRepositoryProvider).fetchPlaces(),
  // Surface failures immediately; the screen offers an explicit retry.
  retry: (retryCount, error) => null,
);

/// Home's bounded offline query. A missing GPS/selection is an explicit state,
/// never a signal to load the global demo list.
final nearbyPlaceRepositoryProvider = Provider<NearbyPlaceRepository>(
  (ref) => ref.watch(osmRegionPlaceRepositoryProvider),
);

final homeNearbyPlacesProvider = FutureProvider<List<Place>?>((ref) async {
  final center = ref.watch(activeDiscoveryCenterProvider);
  if (center == null) return null;
  return ref.watch(nearbyPlaceRepositoryProvider).findNearby(center);
}, retry: (retryCount, error) => null);

final placeProvider = FutureProvider.autoDispose.family<Place?, String>(
  (ref, id) => ref.watch(placeRepositoryProvider).getPlace(id),
  retry: (retryCount, error) => null,
);

List<Place> filterPlaces(List<Place> places, String query, String? category) {
  final normalized = normalizePlaceSearchText(query);
  return places.where((place) {
    return normalizePlaceSearchText(place.name).contains(normalized) &&
        (category == null || place.category == category);
  }).toList();
}
