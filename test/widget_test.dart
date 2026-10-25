import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';

import 'support/auth_fixtures.dart';

void main() {
  testWidgets('Search, detail and favorites share state across navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: [signedInSession], child: const FoodReviewApp()),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'phở');
    await tester.pumpAndSettle();
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
    expect(find.text('Góc Cà Phê'), findsNothing);

    await tester.tap(find.text('Phở Nhà Mình'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết quán'), findsOneWidget);
    await tester.ensureVisible(find.text('Lưu yêu thích'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu yêu thích'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ yêu thích'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yêu thích'));
    await tester.pumpAndSettle();
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
    await tester.tap(find.byTooltip('Bỏ yêu thích'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa lưu nhà hàng nào'), findsOneWidget);

    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    expect(find.text('Góc Cà Phê'), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'phở',
    );
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
