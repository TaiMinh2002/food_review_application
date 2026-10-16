import '../domain/place.dart';
import '../domain/place_repository.dart';

/// Illustrative data only. Replace through placeRepositoryProvider for Firestore.
class DemoPlaceRepository implements PlaceRepository {
  static const places = [
    Place(
      id: 'pho-demo',
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
      name: 'Bánh Mì Buổi Sáng',
      description: 'Bánh mì giòn, nhiều lựa chọn nhân cho bữa ăn nhanh.',
      address: 'Địa chỉ minh họa · Bình Thạnh, TP. Hồ Chí Minh',
      category: 'Ăn nhanh',
      latitude: 10.8015,
      longitude: 106.7100,
    ),
  ];

  @override
  Future<List<Place>> fetchPlaces() async => places;

  @override
  Future<Place?> getPlace(String id) async {
    for (final place in places) {
      if (place.id == id) return place;
    }
    return null;
  }
}
