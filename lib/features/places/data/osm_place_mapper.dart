import '../domain/place.dart';
import '../domain/place_map_repository.dart';

/// Maps only OSM values with an explicit source. In particular, OSM has no
/// rating, review count, menu price or right to reuse an arbitrary photo.
abstract final class OsmPlaceMapper {
  static const _categories = {
    'restaurant': 'Nhà hàng',
    'cafe': 'Cà phê',
    'fast_food': 'Ăn nhanh',
    'food_court': 'Khu ẩm thực',
  };

  static Place? fromElement(Object? value) {
    if (value is! Map) return null;
    final type = value['type'];
    final rawId = value['id'];
    final id = rawId is int ? rawId : null;
    if (!{'node', 'way', 'relation'}.contains(type) || id == null || id <= 0) {
      return null;
    }
    final rawTags = value['tags'];
    if (rawTags is! Map) return null;
    final tags = <String, String>{};
    for (final entry in rawTags.entries) {
      if (entry.key is String && entry.value is String) {
        tags[entry.key as String] = (entry.value as String).trim();
      }
    }
    final amenity = tags['amenity'];
    final category = _categories[amenity];
    final name =
        (tags['name:vi']?.isNotEmpty == true ? tags['name:vi'] : tags['name'])
            ?.trim();
    if (category == null || name == null || name.isEmpty) return null;
    if (tags['disused:amenity'] != null || tags['abandoned:amenity'] != null) {
      return null;
    }

    final center =
        type == 'node' || (value['lat'] is num && value['lon'] is num)
        ? value
        : value['center'];
    if (center is! Map) return null;
    final lat = center['lat'];
    final lon = center['lon'];
    if (lat is! num || lon is! num) return null;
    final point = GeoPoint(lat.toDouble(), lon.toDouble());
    if (!point.isValid) return null;

    final address = tags['addr:full']?.isNotEmpty == true
        ? tags['addr:full']!
        : [
            tags['addr:housenumber'],
            tags['addr:street'],
            tags['addr:suburb'],
            tags['addr:city'],
          ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
    return Place(
      id: 'osm_${type}_$id',
      name: name,
      description: tags['description'] ?? '',
      address: address,
      category: category,
      latitude: point.latitude,
      longitude: point.longitude,
    );
  }
}
