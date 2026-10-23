import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/collections/data/firestore_collection_repository.dart';
import 'package:food_review/features/collections/domain/collection_editor.dart';
import 'package:food_review/features/collections/domain/collection_repository.dart';
import 'package:food_review/features/places/domain/place.dart';

void main() {
  group('FirestoreCollectionRepository unit tests', () {
    test('Validates empty ownerId across methods', () async {
      final repo = FirestoreCollectionRepository(null);

      expect(
        () => repo.getCollections(ownerId: ''),
        throwsA(isA<AppException>()),
      );
      expect(
        () => repo.deleteCollection(ownerId: '', collectionId: 'c1'),
        throwsA(isA<AppException>()),
      );
      expect(
        () => repo.createCollection(
          ownerId: '',
          requestId: 'req1',
          draft: CollectionDraft(name: 'Col', description: '', placeIds: []),
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        () => repo.updateCollection(
          ownerId: '',
          collectionId: 'c1',
          draft: CollectionDraft(name: 'Col', description: '', placeIds: []),
        ),
        throwsA(isA<AppException>()),
      );
      final detail = await repo.getCollection(ownerId: '', collectionId: 'c1');
      expect(detail, isNull);
    });

    test('Validates empty requestId on create', () async {
      final repo = FirestoreCollectionRepository(null);
      expect(
        () => repo.createCollection(
          ownerId: 'user1',
          requestId: '   ',
          draft: CollectionDraft(name: 'Col', description: '', placeIds: []),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('Validates collection name length and content', () async {
      final repo = FirestoreCollectionRepository(null);

      expect(
        () => repo.createCollection(
          ownerId: 'user1',
          requestId: 'req1',
          draft: CollectionDraft(name: '   ', description: '', placeIds: []),
        ),
        throwsA(isA<AppException>()),
      );

      final longName = 'A' * 61;
      expect(
        () => repo.createCollection(
          ownerId: 'user1',
          requestId: 'req1',
          draft: CollectionDraft(name: longName, description: '', placeIds: []),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('Validates description length', () async {
      final repo = FirestoreCollectionRepository(null);
      final longDesc = 'D' * 301;
      expect(
        () => repo.createCollection(
          ownerId: 'user1',
          requestId: 'req1',
          draft: CollectionDraft(
            name: 'Valid Name',
            description: longDesc,
            placeIds: [],
          ),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('Validates place count limit (max 50)', () async {
      final repo = FirestoreCollectionRepository(null);
      final tooManyPlaces = List.generate(51, (i) => 'place_$i');
      expect(
        () => repo.createCollection(
          ownerId: 'user1',
          requestId: 'req1',
          draft: CollectionDraft(
            name: 'Col',
            description: '',
            placeIds: tooManyPlaces,
          ),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('createCollection executes hook and returns requestId', () async {
      var called = false;
      final repo = FirestoreCollectionRepository(
        null,
        createCollectionHook: (ownerId, requestId, draft) async {
          called = true;
          expect(ownerId, 'user1');
          expect(requestId, 'req-abc');
          expect(draft.name, 'Bộ sưu tập phở');
          return requestId;
        },
      );

      final result = await repo.createCollection(
        ownerId: 'user1',
        requestId: 'req-abc',
        draft: CollectionDraft(
          name: 'Bộ sưu tập phở',
          description: 'Ngon tuyệt',
          placeIds: ['place1'],
        ),
      );

      expect(called, isTrue);
      expect(result, 'req-abc');
    });

    test('updateCollection executes hook with valid draft', () async {
      var updated = false;
      final repo = FirestoreCollectionRepository(
        null,
        updateCollectionHook: (ownerId, collectionId, draft) async {
          updated = true;
          expect(ownerId, 'user1');
          expect(collectionId, 'col-123');
          expect(draft.name, 'Tên mới');
        },
      );

      await repo.updateCollection(
        ownerId: 'user1',
        collectionId: 'col-123',
        draft: CollectionDraft(name: 'Tên mới', description: '', placeIds: []),
      );

      expect(updated, isTrue);
    });

    test('deleteCollection executes hook', () async {
      var deleted = false;
      final repo = FirestoreCollectionRepository(
        null,
        deleteCollectionHook: (ownerId, collectionId) async {
          deleted = true;
          expect(ownerId, 'user1');
          expect(collectionId, 'col-999');
        },
      );

      await repo.deleteCollection(ownerId: 'user1', collectionId: 'col-999');
      expect(deleted, isTrue);
    });

    test('getCollection executes hook and resolves details', () async {
      final repo = FirestoreCollectionRepository(
        null,
        getCollectionHook: (ownerId, collectionId) async {
          return CollectionDetail(
            id: collectionId,
            ownerId: ownerId,
            name: 'Cà phê Hà Nội',
            description: 'Quán yên tĩnh',
            places: [
              const CollectionPlace(
                id: 'cafe-1',
                name: 'Cà phê Giảng',
                subtitle: 'Cà phê • Hoàn Kiếm',
              ),
            ],
          );
        },
      );

      final detail = await repo.getCollection(
        ownerId: 'user1',
        collectionId: 'col-cafe',
      );
      expect(detail, isNotNull);
      expect(detail!.name, 'Cà phê Hà Nội');
      expect(detail.places.length, 1);
      expect(detail.places.first.name, 'Cà phê Giảng');
      expect(detail.isDemo, isFalse);
    });

    test('getCollections executes hook with sorting and pagination', () async {
      final items = [
        PlaceCollection(
          id: 'c1',
          ownerId: 'user1',
          name: 'Bộ sưu tập 1',
          description: 'Mô tả',
          placeCount: 3,
          updatedAt: DateTime(2026, 10, 24),
        ),
      ];

      final repo = FirestoreCollectionRepository(
        null,
        getCollectionsHook: (ownerId, sort, cursor, limit) async {
          expect(ownerId, 'user1');
          expect(sort, CollectionSort.recent);
          expect(limit, 10);
          return CollectionPage(items: items, total: 1);
        },
      );

      final page = await repo.getCollections(
        ownerId: 'user1',
        sort: CollectionSort.recent,
        limit: 10,
      );

      expect(page.items.length, 1);
      expect(page.total, 1);
      expect(page.isDemo, isFalse);
    });

    test('PlaceLookup resolves place metadata for collection place', () async {
      final repo = FirestoreCollectionRepository(
        null,
        placeLookup: (id) async {
          if (id == 'osm_node_100') {
            return const Place(
              id: 'osm_node_100',
              name: 'Phở Thìn Lò Đúc',
              description: 'Phở xào lăn',
              category: 'Món Việt',
              address: '13 Lò Đúc',
              latitude: 21.018,
              longitude: 105.856,
              imageUrls: ['https://example.com/pho.jpg'],
            );
          }
          return null;
        },
        getCollectionHook: (ownerId, collectionId) async {
          return CollectionDetail(
            id: collectionId,
            ownerId: ownerId,
            name: 'Phở truyền thống',
            description: '',
            places: [
              const CollectionPlace(
                id: 'osm_node_100',
                name: 'Phở Thìn Lò Đúc',
                subtitle: 'Món Việt • 13 Lò Đúc',
                imageUrl: 'https://example.com/pho.jpg',
              ),
            ],
          );
        },
      );

      final detail = await repo.getCollection(
        ownerId: 'user1',
        collectionId: 'c1',
      );
      expect(detail!.places.first.imageUrl, 'https://example.com/pho.jpg');
    });
  });
}
