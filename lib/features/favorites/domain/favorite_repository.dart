/// Demo contract is synchronous. Use an async/stream contract for Firestore.
abstract interface class FavoriteRepository {
  Set<String> getPlaceIds();
  void toggle(String placeId);
}
