import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/features/want_to_visit/presentation/want_to_visit_providers.dart';
import 'package:food_review/shared/design_system/design_system.dart';

import 'support/auth_harness.dart';

void main() {
  setUpAll(loadAuthFonts);

  testWidgets('Want to visit fits compact large-text light and dark layouts', (
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
      container.read(appRouterProvider).go('/want-to-visit');
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
      expect(find.text('Danh sách của bạn đang trống'), findsOneWidget);
      expect(
        find.widgetWithText(AppButton, 'Khám phá nhà hàng'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Want to visit adds, searches, sorts and removes places', (
    tester,
  ) async {
    final repository = ControlledAuth(user: authTestUser);
    final container = await mountAuth(
      tester,
      repository,
      route: '/want-to-visit',
    );
    await tester.pumpAndSettle();
    container.read(wantToVisitIdsProvider.notifier).toggle('pho-demo');
    container.read(wantToVisitIdsProvider.notifier).toggle('coffee-demo');
    await tester.pumpAndSettle();
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
    expect(find.text('Góc Cà Phê'), findsOneWidget);
    await tester.tap(find.byTooltip('Tìm trong danh sách muốn ghé'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'phở');
    await tester.tap(find.text('Tìm'));
    await tester.pumpAndSettle();
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
    await tester.tap(find.byTooltip('Sắp xếp danh sách muốn ghé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đánh giá cao'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bỏ khỏi muốn ghé'));
    await tester.pumpAndSettle();
    expect(find.text('Không có kết quả'), findsOneWidget);
  });
}
