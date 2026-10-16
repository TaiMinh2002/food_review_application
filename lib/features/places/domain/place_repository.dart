import 'place.dart';

abstract interface class PlaceRepository {
  Future<List<Place>> fetchPlaces();
  Future<Place?> getPlace(String id);
}
