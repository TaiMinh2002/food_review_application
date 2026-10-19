import 'place_search.dart';

/// Search is a server-side query capability, separate from the Home feed.
/// categoryScope is a required root category constraint ANDed with optional
/// subtype categories/other filters BEFORE ordering, count, and pagination.
abstract interface class PlaceSearchRepository {
  Future<PlaceSearchPage> searchPlaces(
    PlaceSearchRequest request, {
    String? cursor,
    int pageSize = 20,
  });
}
