import 'package:characters/characters.dart';

/// Snapshot used by the private editor, independent of SDK/UI types.
class CollectionPlace {
  const CollectionPlace({
    required this.id,
    required this.name,
    required this.subtitle,
    this.imageUrl,
    this.available = true,
  });
  final String id, name, subtitle;
  final String? imageUrl;
  final bool available;
}

class CollectionDetail {
  CollectionDetail({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required List<CollectionPlace> places,
    this.isDemo = false,
  }) : places = List.unmodifiable(places);
  final String id, ownerId, name, description;
  final List<CollectionPlace> places;
  final bool isDemo;
}

class CollectionDraft {
  CollectionDraft({
    required String name,
    required String description,
    required Iterable<String> placeIds,
  }) : name = name.trim(),
       description = description.trim(),
       placeIds = List.unmodifiable(placeIds.toSet());
  final String name, description;
  final List<String> placeIds;
}

const collectionPlaceLimit = 50;
String? validateCollectionName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return 'Vui lòng nhập tên bộ sưu tập.';
  }
  if (name.trim().characters.length > 60) {
    return 'Tên bộ sưu tập tối đa 60 ký tự.';
  }
  return null;
}

String? validateCollectionDescription(String? value) =>
    (value ?? '').trim().characters.length > 300
    ? 'Mô tả tối đa 300 ký tự.'
    : null;

abstract interface class CollectionEditingRepository {
  bool get isDemo;
  Future<CollectionDetail?> getCollection({
    required String ownerId,
    required String collectionId,
  });

  /// Same requestId must not create another collection when a client retries.
  Future<String> createCollection({
    required String ownerId,
    required String requestId,
    required CollectionDraft draft,
  });
  Future<void> updateCollection({
    required String ownerId,
    required String collectionId,
    required CollectionDraft draft,
  });
}
