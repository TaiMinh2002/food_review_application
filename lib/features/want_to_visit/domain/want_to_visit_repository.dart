abstract interface class WantToVisitRepository {
  Stream<Set<String>> watchPlaceIds(String userId);

  Future<void> setWantToVisit({
    required String userId,
    required String placeId,
    required bool value,
  });
}
