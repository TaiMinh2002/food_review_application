import 'dart:async';

import 'package:food_review/features/collections/domain/collection_repository.dart';

typedef CollectionQuery = ({
  String ownerId,
  CollectionSort sort,
  String? cursor,
  int limit,
});

class ScriptedCollections implements CollectionRepository {
  Future<CollectionPage> Function(CollectionQuery query)? onQuery;
  final queries = <CollectionQuery>[];
  final deletes = <(String, String)>[];
  Completer<void>? pendingDelete;
  Object? deleteError;
  @override
  Future<CollectionPage> getCollections({
    required String ownerId,
    CollectionSort sort = CollectionSort.recent,
    String? cursor,
    int limit = 12,
  }) {
    final query = (ownerId: ownerId, sort: sort, cursor: cursor, limit: limit);
    queries.add(query);
    return onQuery?.call(query) ??
        Future.value(CollectionPage(items: [], total: 0));
  }

  @override
  Future<void> deleteCollection({
    required String ownerId,
    required String collectionId,
  }) async {
    deletes.add((ownerId, collectionId));
    if (pendingDelete != null) await pendingDelete!.future;
    if (deleteError != null) throw deleteError!;
  }
}

PlaceCollection sampleCollection(
  String id, {
  String owner = 'user-a',
  int count = 3,
  String? cover,
}) => PlaceCollection(
  id: id,
  ownerId: owner,
  name: 'Bộ sưu tập $id',
  description: 'Riêng tư',
  placeCount: count,
  updatedAt: DateTime(2026, 10, 20),
  coverUrl: cover,
);
