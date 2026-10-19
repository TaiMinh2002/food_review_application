import '../domain/place.dart';
import '../domain/place_repository.dart';

/// Illustrative data only. Replace through placeRepositoryProvider for Firestore.
class DemoPlaceRepository implements PlaceRepository {
  DemoPlaceRepository({List<Place> data = places})
    : _places = List.unmodifiable(data);

  final List<Place> _places;

  static const places = [
    Place(
      id: 'pho-demo',
      imageUrls: ['assets/images/demo/pho.jpg'],
      averageRating: 4.8,
      reviewCount: 328,
      minPrice: 55000,
      maxPrice: 85000,
      name: 'Phở Nhà Mình',
      description:
          'Nước dùng thanh, bánh phở mềm. Gợi ý cho một bữa sáng ấm bụng.',
      address: 'Địa chỉ minh họa · Quận 1, TP. Hồ Chí Minh',
      category: 'Món Việt',
      latitude: 10.7769,
      longitude: 106.7009,
    ),
    Place(
      id: 'coffee-demo',
      imageUrls: ['assets/images/demo/coffee.jpg'],
      averageRating: 4.7,
      reviewCount: 194,
      minPrice: 25000,
      maxPrice: 60000,
      name: 'Góc Cà Phê',
      description:
          'Một góc nhỏ để thưởng thức cà phê và trò chuyện cùng bạn bè.',
      address: 'Địa chỉ minh họa · Quận 3, TP. Hồ Chí Minh',
      category: 'Cà phê',
      latitude: 10.7840,
      longitude: 106.6839,
    ),
    Place(
      id: 'banh-mi-demo',
      imageUrls: ['assets/images/demo/banh_mi.jpg'],
      averageRating: 4.6,
      reviewCount: 145,
      minPrice: 25000,
      maxPrice: 45000,
      name: 'Bánh Mì Buổi Sáng',
      description: 'Bánh mì giòn, nhiều lựa chọn nhân cho bữa ăn nhanh.',
      address: 'Địa chỉ minh họa · Bình Thạnh, TP. Hồ Chí Minh',
      category: 'Ăn nhanh',
      latitude: 10.8015,
      longitude: 106.7100,
    ),
  ];

  @override
  Future<List<Place>> fetchPlaces() async => _places;

  @override
  Future<Place?> getPlace(String id) async {
    for (final place in _places) {
      if (place.id == id) return place;
    }
    return null;
  }
}
