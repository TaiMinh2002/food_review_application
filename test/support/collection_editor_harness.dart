import 'dart:async';

import 'package:food_review/features/collections/data/demo_collection_repository.dart';
import 'package:food_review/features/collections/domain/collection_editor.dart';
import 'package:food_review/features/collections/domain/collection_repository.dart';

class ControlledCollectionEditor
    implements CollectionRepository, CollectionEditingRepository {
  final source = DemoCollectionRepository(seedExamples: false);
  Object? loadError, saveError;
  Completer<CollectionDetail?>? pendingLoad;
  Completer<void>? pendingSave;
  bool wrongOwner = false, missing = false;
  int creates = 0, updates = 0;
  final requestIds = <String>[];
  CollectionDraft? lastDraft;
  @override
  bool get isDemo => true;
  @override
  Future<CollectionPage> getCollections({
    required String ownerId,
    CollectionSort sort = CollectionSort.recent,
    String? cursor,
    int limit = 12,
  }) => source.getCollections(
    ownerId: ownerId,
    sort: sort,
    cursor: cursor,
    limit: limit,
  );
  @override
  Future<void> deleteCollection({
    required String ownerId,
    required String collectionId,
  }) => source.deleteCollection(ownerId: ownerId, collectionId: collectionId);
  @override
  Future<CollectionDetail?> getCollection({
    required String ownerId,
    required String collectionId,
  }) async {
    if (pendingLoad != null) return pendingLoad!.future;
    if (loadError != null) throw loadError!;
    if (missing) return null;
    return CollectionDetail(
      id: collectionId,
      ownerId: wrongOwner ? 'other' : ownerId,
      name: 'Quán ngon Hà Nội',
      description: 'Những quán ăn muốn ghé lại.',
      isDemo: true,
      places: [
        const CollectionPlace(
          id: 'pho-demo',
          name: 'Phở Nhà Mình',
          subtitle: 'Món Việt • Quận 1',
          imageUrl: 'assets/images/demo/pho.jpg',
        ),
      ],
    );
  }

  @override
  Future<String> createCollection({
    required String ownerId,
    required String requestId,
    required CollectionDraft draft,
  }) async {
    creates++;
    requestIds.add(requestId);
    lastDraft = draft;
    if (pendingSave != null) await pendingSave!.future;
    if (saveError != null) throw saveError!;
    return source.createCollection(
      ownerId: ownerId,
      requestId: requestId,
      draft: draft,
    );
  }

  @override
  Future<void> updateCollection({
    required String ownerId,
    required String collectionId,
    required CollectionDraft draft,
  }) async {
    updates++;
    lastDraft = draft;
    if (pendingSave != null) await pendingSave!.future;
    if (saveError != null) throw saveError!;
  }
}
