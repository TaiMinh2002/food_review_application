import 'gallery.dart';
import 'place.dart';

/// Reads the bounded media snapshot already supplied for a place, or one exact
/// review. Backend sources must bound embedded media; never scan all reviews.
abstract interface class GalleryRepository {
  Future<GalleryCollection> getPhotos(Place place, GalleryRequest request);
}
