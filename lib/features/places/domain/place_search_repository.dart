import 'place_search.dart';

/// Search is a server-side query capability, separate from the Home feed.
abstract interface class PlaceSearchRepository {
  Future<PlaceSearchPage> searchPlaces(
    PlaceSearchRequest request, {
    String? cursor,
    int pageSize = 20,
  });
}
