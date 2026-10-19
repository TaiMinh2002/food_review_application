import '../domain/place.dart';
import 'demo_place_repository.dart';

/// Fixtures for image fallback and repository override tests.
/// Images are illustrative Stitch assets, not evidence of actual venues.
abstract final class DemoPlaceFixtures {
  static const empty = <Place>[];
  static final withoutImages = [
    for (final place in DemoPlaceRepository.places)
      Place(
        id: place.id,
        name: place.name,
        description: place.description,
        address: place.address,
        category: place.category,
        latitude: place.latitude,
        longitude: place.longitude,
        averageRating: place.averageRating,
        reviewCount: place.reviewCount,
        minPrice: place.minPrice,
        maxPrice: place.maxPrice,
      ),
  ];

  static const withImages = DemoPlaceRepository.places;
  static final brokenImages = _withImageUrls(
    List.filled(withoutImages.length, 'https://images.invalid/food-demo.jpg'),
  );

  static List<Place> _withImageUrls(List<String> urls) => List.unmodifiable([
    for (var i = 0; i < withoutImages.length; i++)
      Place(
        id: withoutImages[i].id,
        name: withoutImages[i].name,
        description: withoutImages[i].description,
        address: withoutImages[i].address,
        category: withoutImages[i].category,
        latitude: withoutImages[i].latitude,
        longitude: withoutImages[i].longitude,
        imageUrls: List.unmodifiable([urls[i]]),
        averageRating: withoutImages[i].averageRating,
        reviewCount: withoutImages[i].reviewCount,
        minPrice: withoutImages[i].minPrice,
        maxPrice: withoutImages[i].maxPrice,
      ),
  ]);
}
