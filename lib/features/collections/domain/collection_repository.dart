/// A private collection summary. Counts/covers come from its own membership.
class PlaceCollection {
  const PlaceCollection({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.placeCount,
    required this.updatedAt,
    this.coverUrl,
  });
  final String id, ownerId, name, description;
  final int placeCount;
  final DateTime updatedAt;
  final String? coverUrl;
}

enum CollectionSort { recent, name, mostPlaces }

class CollectionPage {
  CollectionPage({
    required List<PlaceCollection> items,
    required this.total,
    this.nextCursor,
    this.isDemo = false,
  }) : items = List.unmodifiable(items);
  final List<PlaceCollection> items;
  final int total;
  final String? nextCursor;
  final bool isDemo;
}

abstract interface class CollectionRepository {
  /// Implementations must query by owner before sorting/paging.
  Future<CollectionPage> getCollections({
    required String ownerId,
    CollectionSort sort = CollectionSort.recent,
    String? cursor,
    int limit = 12,
  });

  /// Delete this collection/membership only, never favorites or want-to-visit.
  /// A backend adapter must enforce authenticated ownership and clean children.
  Future<void> deleteCollection({
    required String ownerId,
    required String collectionId,
  });
}
