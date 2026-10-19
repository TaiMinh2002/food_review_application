import '../domain/place.dart';
import '../domain/place_menu_item.dart';
import '../domain/place_repository.dart';
import '../domain/place_search.dart';
import '../domain/place_search_repository.dart';
import '../domain/place_map_repository.dart';
import '../../../core/errors/app_exception.dart';

/// Illustrative data only. Replace through placeRepositoryProvider for Firestore.
class DemoPlaceRepository
    implements PlaceRepository, PlaceSearchRepository, PlaceMapRepository {
  DemoPlaceRepository({List<Place> data = places})
    : _places = List.unmodifiable(data);

  final List<Place> _places;

  static const places = [
    Place(
      id: 'pho-demo',
      foodCategories: ['Phở'],
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
      foodCategories: ['Cà phê'],
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
      foodCategories: ['Bánh mì'],
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

  @override
  Future<PlaceMapResult> findInViewport(
    MapViewport viewport, {
    required PlaceSearchRequest filters,
    GeoPoint? near,
    int limit = 50,
  }) async {
    final bounded = _places.where((place) {
      final point = GeoPoint(place.latitude, place.longitude);
      return viewport.contains(point) &&
          (near == null || near.distanceTo(point) < 1000);
    }).toList();
    final page = await DemoPlaceRepository(data: bounded)
        .searchPlaces(filters, pageSize: limit);
    return PlaceMapResult(
      places: page.items,
      hasMore: page.nextCursor != null,
      isDemo: true,
    );
  }

  @override
  Future<PlaceSearchPage> searchPlaces(
    PlaceSearchRequest request, {
    String? cursor,
    int pageSize = 20,
  }) async {
    if (pageSize < 1 || pageSize > 50) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const AppException(
        'Không thể tải trang kết quả. Vui lòng tìm lại.',
      );
    }
    final query = normalizePlaceSearchText(request.query);
    final tokens = query.split(' ').where((token) => token.isNotEmpty);
    final matches = _places.where((place) {
      final names = normalizePlaceSearchText(
        [place.name, ...place.menuItems.map((item) => item.name)].join(' '),
      );
      final matchesCategory =
          request.categories.isEmpty ||
          request.categories.contains(place.category) ||
          request.categories.any(place.foodCategories.contains);
      final matchesRating =
          request.minRating == null ||
          place.reviewCount > 0 && place.averageRating >= request.minRating!;
      final filtersPrice = request.minPrice != null || request.maxPrice != null;
      final matchesPrice =
          !filtersPrice ||
          place.minPrice != null &&
              place.maxPrice != null &&
              (request.minPrice == null ||
                  place.maxPrice! >= request.minPrice!) &&
              (request.maxPrice == null ||
                  place.minPrice! <= request.maxPrice!);
      return matchesCategory &&
          matchesRating &&
          matchesPrice &&
          request.amenities.every(place.amenities.contains) &&
          tokens.every(names.contains);
    }).toList();
    int relevance(Place place) {
      final name = normalizePlaceSearchText(place.name);
      if (query.isEmpty || name == query) return 0;
      if (name.startsWith(query)) return 1;
      return name.contains(query) ? 2 : 3;
    }

    matches.sort((a, b) {
      final order = switch (request.sort) {
        PlaceSearchSort.relevance => relevance(a).compareTo(relevance(b)),
        PlaceSearchSort.rating => b.averageRating.compareTo(a.averageRating),
        PlaceSearchSort.reviews => b.reviewCount.compareTo(a.reviewCount),
        PlaceSearchSort.price =>
          a.minPrice == null
              ? (b.minPrice == null ? 0 : 1)
              : b.minPrice == null
              ? -1
              : a.minPrice!.compareTo(b.minPrice!),
      };
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    final items = matches.skip(offset).take(pageSize).toList();
    return PlaceSearchPage(
      items: items,
      categories: const [
        'Phở',
        'Bún',
        'Cơm',
        'Bánh mì',
        'Đồ nướng',
        'Lẩu',
        'Cà phê',
        'Món chay',
      ],
      amenities: _places.expand((place) => place.amenities).toSet().toList()
        ..sort(),
      totalCount: matches.length,
      nextCursor: offset + items.length < matches.length
          ? '${offset + items.length}'
          : null,
      isDemo: true,
    );
  }
}
