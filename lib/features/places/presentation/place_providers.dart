import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_place_repository.dart';
import '../domain/place.dart';
import '../domain/place_repository.dart';

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => DemoPlaceRepository(),
);

final placesProvider = FutureProvider<List<Place>>(
  (ref) => ref.watch(placeRepositoryProvider).fetchPlaces(),
  // Surface failures immediately; the screen offers an explicit retry.
  retry: (retryCount, error) => null,
);

final placeProvider = FutureProvider.autoDispose.family<Place?, String>(
  (ref, id) => ref.watch(placeRepositoryProvider).getPlace(id),
  retry: (retryCount, error) => null,
);

List<Place> filterPlaces(List<Place> places, String query, String? category) {
  final normalized = query.trim().toLowerCase();
  return places.where((place) {
    return place.name.toLowerCase().contains(normalized) &&
        (category == null || place.category == category);
  }).toList();
}
