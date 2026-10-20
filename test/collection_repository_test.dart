import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/collections/data/demo_collection_repository.dart';
import 'package:food_review/features/collections/domain/collection_repository.dart';

void main() {
  test('Demo counts match unique membership; owner pages and delete stay independent', () async {
    final repository = DemoCollectionRepository();
    final first = await repository.getCollections(ownerId: 'a', limit: 2);
    expect(first.isDemo, isTrue);
    expect(first.total, 4);
    expect(first.items.map((item) => item.placeCount), [2, 2]);
    expect(first.items.every((item) => item.ownerId == 'a'), isTrue);
    final next = await repository.getCollections(
      ownerId: 'a',
      cursor: first.nextCursor,
      limit: 2,
    );
    expect(next.items.map((item) => item.placeCount), [1, 1]);
    expect(next.nextCursor, isNull);
    expect({
      ...first.items.map((item) => item.id),
      ...next.items.map((item) => item.id),
    }, hasLength(4));
    await repository.deleteCollection(
      ownerId: 'a',
      collectionId: first.items.first.id,
    );
    expect((await repository.getCollections(ownerId: 'a')).total, 3);
    expect((await repository.getCollections(ownerId: 'b')).total, 4);
    await expectLater(
      repository.getCollections(ownerId: 'a', cursor: first.nextCursor),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      repository.deleteCollection(
        ownerId: 'a',
        collectionId: first.items.first.id,
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('Sort, empty and cursor validation reflect repository data', () async {
    final repository = DemoCollectionRepository();
    final page = await repository.getCollections(
      ownerId: 'a',
      sort: CollectionSort.mostPlaces,
    );
    expect(page.items.map((item) => item.placeCount), [2, 2, 1, 1]);
    final byName = await repository.getCollections(
      ownerId: 'a',
      sort: CollectionSort.name,
    );
    expect(byName.items.map((item) => item.name), [
      'Ăn ngon tiết kiệm',
      'Cà phê đẹp',
      'Đi hẹn hò',
      'Quán ngon Hà Nội',
    ]);
    final empty = DemoCollectionRepository(seedExamples: false);
    expect((await empty.getCollections(ownerId: 'a')).items, isEmpty);
    await expectLater(
      repository.getCollections(ownerId: ''),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      repository.getCollections(ownerId: 'a', cursor: 'bad'),
      throwsA(isA<AppException>()),
    );
  });
}
