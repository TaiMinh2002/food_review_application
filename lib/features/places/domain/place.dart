import 'place_menu_item.dart';

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.imageUrls = const [],
    this.averageRating = 0,
    this.reviewCount = 0,
    this.minPrice,
    this.maxPrice,
    this.openingHours,
    this.amenities = const [],
    this.menuItems = const [],
    this.isDemo = false,
  });

  final String id;
  final String name;
  final String description;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final double averageRating;
  final int reviewCount;
  final int? minPrice, maxPrice;
  final String? openingHours;
  final List<String> amenities;
  final List<PlaceMenuItem> menuItems;
  final bool isDemo;
}
