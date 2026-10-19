import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/shared/design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/auth_harness.dart';

void main() {
  setUpAll(loadAuthFonts);

  testWidgets('Favorites fits small large-text light and dark layouts', (
    tester,
  ) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final repository = ControlledAuth(user: authTestUser);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() async {
        container.dispose();
        await repository.events.close();
      });
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      container.read(themeModeProvider.notifier).setMode(mode);
      container.read(appRouterProvider).go('/favorites');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.6),
              padding: EdgeInsets.only(top: 44, bottom: 24),
              viewPadding: EdgeInsets.only(top: 44, bottom: 24),
            ),
            child: const FoodReviewApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bạn chưa lưu nhà hàng nào'), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, 'Khám phá nhà hàng'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Favorites search, category, sort and remove update the list', (
    tester,
  ) async {
    final repository = ControlledAuth(user: authTestUser);
    final container = await mountAuth(tester, repository, route: '/favorites');
    await tester.pumpAndSettle();
    container.read(favoriteIdsProvider.notifier).toggle('pho-demo');
    container.read(favoriteIdsProvider.notifier).toggle('coffee-demo');
    await tester.pumpAndSettle();
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
    expect(find.text('Góc Cà Phê'), findsOneWidget);
    expect(find.widgetWithText(AppChip, 'Món Việt'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppChip, 'Món Việt'));
    await tester.pumpAndSettle();
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
    expect(find.text('Góc Cà Phê'), findsNothing);
    await tester.tap(find.byTooltip('Tìm kiếm yêu thích'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'phở');
    await tester.tap(find.text('Tìm'));
    await tester.pumpAndSettle();
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
    await tester.tap(find.byTooltip('Sắp xếp yêu thích'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tên A–Z'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bỏ yêu thích'));
    await tester.pumpAndSettle();
    expect(find.text('Không có kết quả'), findsOneWidget);
  });
}
