import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/place_repository.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';

void main() {
  testWidgets('Search, detail and favorites share state across navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FoodReviewApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'phở');
    await tester.pumpAndSettle();
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
    expect(find.text('Góc Cà Phê'), findsNothing);

    await tester.tap(find.text('Phở Nhà Mình'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết quán'), findsOneWidget);
    await tester.tap(find.text('Lưu yêu thích'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ yêu thích'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đã lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
    await tester.tap(find.byTooltip('Bỏ yêu thích'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bạn chưa lưu quán nào'), findsOneWidget);

    await tester.tap(find.text('Khám phá'));
    await tester.pumpAndSettle();
    expect(find.text('Góc Cà Phê'), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'phở',
    );
  });

  testWidgets('Empty repository shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placeRepositoryProvider.overrideWithValue(_EmptyRepository()),
        ],
        child: const FoodReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy quán phù hợp.'), findsOneWidget);
  });

  testWidgets('Repository failure can be retried', (tester) async {
    final repository = _FailOnceRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [placeRepositoryProvider.overrideWithValue(repository)],
        child: const FoodReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tải được danh sách quán.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('Không tìm thấy quán phù hợp.'), findsOneWidget);
  });

  testWidgets('Unknown place ID shows not found', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FoodReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Enter a detail route without passing an in-memory Place object.
    container.read(appRouterProvider).go('/places/missing');
    await tester.pumpAndSettle();
    expect(find.text('Quán không tồn tại.'), findsOneWidget);
  });
}

class _EmptyRepository implements PlaceRepository {
  @override
  Future<List<Place>> fetchPlaces() async => [];

  @override
  Future<Place?> getPlace(String id) async => null;
}

class _FailOnceRepository extends _EmptyRepository {
  int calls = 0;

  @override
  Future<List<Place>> fetchPlaces() async {
    calls++;
    if (calls == 1) throw Exception('Simulated network failure');
    return [];
  }
}
