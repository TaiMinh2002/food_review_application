import '../domain/favorite_repository.dart';

/// Session-only favorites; restarting the app clears them.
class MemoryFavoriteRepository implements FavoriteRepository {
  final _placeIds = <String>{};

  @override
  Set<String> getPlaceIds() => Set.unmodifiable(_placeIds);

  @override
  void toggle(String placeId) {
    if (!_placeIds.remove(placeId)) _placeIds.add(placeId);
  }
}
