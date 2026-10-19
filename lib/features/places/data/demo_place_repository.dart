import '../domain/place.dart';
import '../domain/place_menu_item.dart';
import '../domain/place_repository.dart';

/// Illustrative data only. Replace through placeRepositoryProvider for Firestore.
class DemoPlaceRepository implements PlaceRepository {
  DemoPlaceRepository({List<Place> data = places})
    : _places = List.unmodifiable(data);

  final List<Place> _places;

  static const places = [
    Place(
      id: 'pho-demo',
      isDemo: true,
      openingHours: '06:00 – 20:30',
      amenities: ['Ăn tại chỗ', 'Mang về', 'Chuyển khoản / QR', 'Có chỗ để xe'],
      menuItems: [
        PlaceMenuItem(
          name: 'Phở Bò Tái Lăn',
          description: 'Thịt bò xào lăn thơm tỏi đượm vị',
          price: 75000,
          imageUrl: 'assets/images/demo/dish_tai_lan.jpg',
          label: 'Gợi ý thử',
        ),
        PlaceMenuItem(
          name: 'Phở Tái Nạm Gầu',
          description: 'Gầu giòn, nạm chín cùng nước dùng thanh',
          price: 85000,
          imageUrl: 'assets/images/demo/dish_nam_gau.jpg',
        ),
        PlaceMenuItem(
          name: 'Quẩy Giòn & Trứng Chần',
          description: 'Món ăn kèm cho bát phở nóng',
          price: 15000,
          imageUrl: 'assets/images/demo/dish_quay.jpg',
        ),
        PlaceMenuItem(
          name: 'Phở Bò Chín Nạm',
          description: 'Nước dùng thanh trong truyền thống',
          price: 65000,
          imageUrl: 'assets/images/demo/dish_chin.jpg',
        ),
      ],
      imageUrls: [
        'assets/images/demo/pho.jpg',
        'assets/images/demo/detail_hero.jpg',
        'assets/images/demo/review_pho_1.jpg',
        'assets/images/demo/review_pho_2.jpg',
      ],
      averageRating: 4.8,
      reviewCount: 328,
      minPrice: 55000,
      maxPrice: 85000,
      name: 'Phở Nhà Mình',
      description: 'Một gợi ý minh họa cho bữa sáng với nước dùng thanh, bánh phở mềm và thịt bò thơm. Bát phở nóng ăn cùng hành hoa, rau thơm và quẩy giòn mang lại cảm giác gần gũi của bữa ăn Việt. Nội dung này dùng để xem thử giao diện, không phải thông tin quán đã xác minh.',
      address: 'Địa chỉ minh họa · Quận 1, TP. Hồ Chí Minh',
      category: 'Món Việt',
      latitude: 10.7769,
      longitude: 106.7009,
    ),
    Place(
      id: 'coffee-demo',
      isDemo: true,
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
      isDemo: true,
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
