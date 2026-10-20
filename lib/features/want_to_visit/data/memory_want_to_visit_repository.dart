import 'dart:async';

import '../domain/want_to_visit_repository.dart';

/// Session-only demo adapter; replace with a user-scoped backend later.
class MemoryWantToVisitRepository implements WantToVisitRepository {
  final _placeIds = <String>{};
  final _changes = StreamController<Set<String>>.broadcast(sync: true);

  @override
  Stream<Set<String>> watchPlaceIds(String userId) async* {
    yield Set.unmodifiable(_placeIds);
    yield* _changes.stream;
  }

  @override
  Future<void> setWantToVisit({
    required String userId,
    required String placeId,
    required bool value,
  }) async {
    if (value) {
      _placeIds.add(placeId);
    } else {
      _placeIds.remove(placeId);
    }
    _changes.add(Set.unmodifiable(_placeIds));
  }

  void dispose() => _changes.close();
}
