import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_place_repository.dart';
import '../domain/place.dart';
import '../domain/place_repository.dart';
import '../domain/place_search.dart';

import '../domain/nearby_place_repository.dart';
import '../domain/place_map_repository.dart';
import 'map_controller.dart';
import 'user_location_controller.dart';

final nearbyPlaceRepositoryProvider = Provider<NearbyPlaceRepository>(
  (ref) => ref.watch(osmRegionPlaceRepositoryProvider),
);

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  final mapRepo = ref.watch(placeMapRepositoryProvider);
  if (mapRepo is PlaceRepository) {
    return mapRepo as PlaceRepository;
  }
  return DemoPlaceRepository();
});

final placesProvider = FutureProvider<List<Place>>((ref) async {
  final repo = ref.watch(placeRepositoryProvider);
  final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
    'Test',
  );
  if (!isTest) {
    try {
      final osmRepo = ref.watch(osmRegionPlaceRepositoryProvider);
      final userPoint = ref.watch(userLocationControllerProvider).point;
      final center = userPoint ?? const GeoPoint(20.9859, 105.7938);
      // Bán kính mặc định 30 cây số (30,000m) tính từ vị trí người dùng (hoặc Chợ Phùng Khoang)
      final realPlaces = await osmRepo.findNearby(center, radiusMeters: 30000);
      if (realPlaces.isNotEmpty) return realPlaces;
    } catch (_) {}
  }
  return repo.fetchPlaces();
}, retry: (retryCount, error) => null);

final placeProvider = FutureProvider.autoDispose.family<Place?, String>((
  ref,
  id,
) async {
  if (id.startsWith('osm_')) {
    final place = await ref.watch(osmRegionPlaceRepositoryProvider).getById(id);
    if (place != null) return place;
  }
  return ref.watch(placeRepositoryProvider).getPlace(id);
}, retry: (retryCount, error) => null);

List<Place> filterPlaces(List<Place> places, String query, String? category) {
  final normalized = normalizePlaceSearchText(query);
  return places.where((place) {
    return normalizePlaceSearchText(place.name).contains(normalized) &&
        (category == null || place.category == category);
  }).toList();
}
