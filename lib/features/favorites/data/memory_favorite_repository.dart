import 'dart:async';

import '../domain/favorite_repository.dart';

/// Session-only favorites; restarting the app clears them.
class MemoryFavoriteRepository implements FavoriteRepository {
  final _placeIds = <String>{};
  final _changes = StreamController<Set<String>>.broadcast(sync: true);

  /// Compatibility helpers for local domain tests and fixtures.
  Set<String> getPlaceIds() => Set.unmodifiable(_placeIds);

  void toggle(String placeId) {
    if (!_placeIds.remove(placeId)) _placeIds.add(placeId);
    _emit();
  }

  @override
  Stream<Set<String>> watchPlaceIds(String userId) async* {
    yield getPlaceIds();
    yield* _changes.stream;
  }

  @override
  Future<void> setFavorite({
    required String userId,
    required String placeId,
    required bool value,
  }) async {
    if (value) {
      _placeIds.add(placeId);
    } else {
      _placeIds.remove(placeId);
    }
    _emit();
  }

  void _emit() => _changes.add(getPlaceIds());

  void dispose() {
    _changes.close();
  }
}
