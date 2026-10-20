import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/collections/data/demo_collection_repository.dart';
import 'package:food_review/features/collections/domain/collection_editor.dart';

void main() {
  test('Character limits count Vietnamese combining marks and emoji as displayed characters', () {
    expect(validateCollectionName('a\u0301' * 60), isNull);
    expect(validateCollectionName('👩‍🍳' * 60), isNull);
    expect(validateCollectionName('👩‍🍳' * 61), isNotNull);
    expect(validateCollectionDescription('a\u0301' * 300), isNull);
  });

  test('Create normalizes text, deduplicates membership, retries idempotently and derives cover/count', () async {
    final repository = DemoCollectionRepository(seedExamples: false);
    final draft = CollectionDraft(
      name: '  Cuối tuần  ',
      description: '  Gần nhà  ',
      placeIds: ['coffee-demo', 'coffee-demo', 'pho-demo'],
    );
    final id = await repository.createCollection(
      ownerId: 'a',
      requestId: 'request',
      draft: draft,
    );
    expect(
      await repository.createCollection(
        ownerId: 'a',
        requestId: 'request',
        draft: draft,
      ),
      id,
    );
    await expectLater(
      repository.createCollection(
        ownerId: 'a',
        requestId: 'request',
        draft: CollectionDraft(
          name: 'Nội dung khác',
          description: '',
          placeIds: [],
        ),
      ),
      throwsA(isA<AppException>()),
    );
    final detail = (await repository.getCollection(
      ownerId: 'a',
      collectionId: id,
    ))!;
    expect(detail.name, 'Cuối tuần');
    expect(detail.description, 'Gần nhà');
    expect(detail.places.map((p) => p.id), ['coffee-demo', 'pho-demo']);
    final page = await repository.getCollections(ownerId: 'a');
    expect(page.total, 1);
    expect(page.items.single.placeCount, 2);
    expect(page.items.single.coverUrl, detail.places.first.imageUrl);
    expect(
      await repository.getCollection(ownerId: 'b', collectionId: id),
      isNull,
    );
  });

  test('Edit keeps ID/count of collections and can save zero members with no cover', () async {
    final repository = DemoCollectionRepository();
    final before = await repository.getCollections(ownerId: 'a');
    await repository.updateCollection(
      ownerId: 'a',
      collectionId: 'hanoi-demo',
      draft: CollectionDraft(name: 'Mới', description: '', placeIds: []),
    );
    final after = await repository.getCollections(ownerId: 'a');
    expect(after.total, before.total);
    final edited = after.items.firstWhere((c) => c.id == 'hanoi-demo');
    expect(edited.name, 'Mới');
    expect(edited.placeCount, 0);
    expect(edited.coverUrl, isNull);
    expect(
      (await repository.getCollections(ownerId: 'b')).items.first.name,
      'Quán ngon Hà Nội',
    );
  });

  test('Invalid names, long descriptions, missing restaurants and unknown edit IDs do not write', () async {
    final repository = DemoCollectionRepository(seedExamples: false);
    for (final draft in [
      CollectionDraft(name: '  ', description: '', placeIds: []),
      CollectionDraft(name: 'x' * 61, description: '', placeIds: []),
      CollectionDraft(name: 'a', description: 'x' * 301, placeIds: []),
      CollectionDraft(name: 'a', description: '', placeIds: ['missing']),
    ]) {
      await expectLater(
        repository.createCollection(
          ownerId: 'a',
          requestId: 'request',
          draft: draft,
        ),
        throwsA(isA<AppException>()),
      );
    }
    await expectLater(
      repository.updateCollection(
        ownerId: 'a',
        collectionId: 'missing',
        draft: CollectionDraft(name: 'a', description: '', placeIds: []),
      ),
      throwsA(isA<AppException>()),
    );
    expect((await repository.getCollections(ownerId: 'a')).total, 0);
  });
}
