abstract interface class FavoriteRepository {
  Stream<Set<String>> watchPlaceIds(String userId);
  Future<void> setFavorite({
    required String userId,
    required String placeId,
    required bool value,
  });
}
