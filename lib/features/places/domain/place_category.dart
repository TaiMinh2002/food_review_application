import 'place.dart';

/// Stable application taxonomy. Labels are data tags, IDs are route identities.
/// This catalogue contains no restaurant counts or claims from the prototype.
class PlaceCategory {
  const PlaceCategory(
    this.id,
    this.label, {
    this.subcategories = const [],
    this.tags = const [],
  });
  final String id, label;
  final List<String> subcategories, tags;

  /// These IDs correspond directly to amenity tags retained by the OSM package.
  /// Cuisine-specific categories require source tags that this package lacks.
  bool get isOsmSupported =>
      const {'nha-hang', 'ca-phe', 'an-nhanh', 'khu-am-thuc'}.contains(id);

  static List<PlaceCategory> get osmValues => values
      .where((category) => category.isOsmSupported)
      .toList(growable: false);

  bool contains(Place place) => {
    place.category,
    ...place.foodCategories,
  }.any((tag) => tag == label || tags.contains(tag));

  static const values = [
    PlaceCategory('nha-hang', 'Nhà hàng'),
    PlaceCategory('khu-am-thuc', 'Khu ẩm thực'),
    PlaceCategory(
      'mon-viet',
      'Món Việt',
      subcategories: ['Phở', 'Bún', 'Cơm tấm', 'Bánh mì', 'Đồ ăn vặt'],
      tags: [
        'Phở',
        'Bún',
        'Cơm',
        'Cơm tấm',
        'Bánh mì',
        'Đồ ăn vặt',
        'Đồ nướng',
        'Lẩu',
        'Món chay',
      ],
    ),
    PlaceCategory('ca-phe', 'Cà phê'),
    PlaceCategory(
      'an-nhanh',
      'Ăn nhanh',
      tags: ['Bánh mì'],
      subcategories: ['Bánh mì'],
    ),
    PlaceCategory('pho', 'Phở'),
    PlaceCategory('bun', 'Bún'),
    PlaceCategory('com', 'Cơm', tags: ['Cơm tấm'], subcategories: ['Cơm tấm']),
    PlaceCategory('com-tam', 'Cơm tấm'),
    PlaceCategory('banh-mi', 'Bánh mì'),
    PlaceCategory('do-an-vat', 'Đồ ăn vặt'),
    PlaceCategory('do-nuong', 'Đồ nướng'),
    PlaceCategory('lau', 'Lẩu'),
    PlaceCategory('mon-chay', 'Món chay'),
  ];

  static PlaceCategory? byId(String? id) =>
      values.where((category) => category.id == id).firstOrNull;
  static PlaceCategory? byLabel(String label) =>
      values.where((category) => category.label == label).firstOrNull;
}
