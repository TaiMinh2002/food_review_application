import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/features/favorites/data/memory_favorite_repository.dart';
import 'package:food_review/features/places/data/demo_place_repository.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';
import 'package:food_review/features/reviews/domain/review.dart';

void main() {
  test('Search trims input, ignores case and combines with category', () {
    final places = DemoPlaceRepository.places;
    expect(filterPlaces(places, '  PHỞ  ', 'Món Việt').single.id, 'pho-demo');
    expect(filterPlaces(places, 'phở', 'Cà phê'), isEmpty);
    expect(filterPlaces(places, '', null).length, places.length);
  });

  test('Favorite snapshots cannot mutate repository state', () {
    final repository = MemoryFavoriteRepository();
    repository.toggle('pho-demo');
    final snapshot = repository.getPlaceIds();
    expect(() => snapshot.add('other'), throwsUnsupportedError);
    repository.toggle('pho-demo');
    expect(repository.getPlaceIds(), isEmpty);
    expect(snapshot, contains('pho-demo'));
  });

  test('Review rejects invalid rating and blank content', () {
    Review create(int rating, String content) => Review(
      id: 'review',
      placeId: 'place',
      userId: 'user',
      rating: rating,
      content: content,
      createdAt: DateTime.utc(2026),
    );
    expect(() => create(0, 'Ngon'), throwsArgumentError);
    expect(() => create(6, 'Ngon'), throwsArgumentError);
    expect(() => create(5, '   '), throwsArgumentError);
    expect(create(5, 'Đồ ăn ngon').rating, 5);
  });
}
