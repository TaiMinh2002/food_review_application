import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';
import 'package:food_review/features/want_to_visit/presentation/want_to_visit_providers.dart';

import 'support/auth_harness.dart';

Future<void> reveal(
  WidgetTester tester,
  Finder target, {
  double delta = 250,
}) async {
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

Future<void> confirmLogout(WidgetTester tester) async {
  await reveal(tester, find.text('Đăng xuất'));
  await tester.tap(find.text('Đăng xuất'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Đăng xuất'),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadAuthFonts);

  testWidgets(
    'Theme choice changes the app and survives route changes; Back returns to Profile',
    (tester) async {
      final container = await mountAuth(
        tester,
        ControlledAuth(),
        route: '/settings',
      );
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      await reveal(tester, find.text('Chế độ hiển thị'));
      await tester.tap(find.text('Chế độ hiển thị'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tối'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.text('Cài đặt'))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.byTooltip('Quay lại hồ sơ cá nhân'));
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/profile');
      await tester.tap(find.byTooltip('Cài đặt'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
      await reveal(tester, find.text('Chế độ hiển thị'));
      await tester.tap(find.text('Chế độ hiển thị'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hệ thống'));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.system);
    },
  );

  testWidgets(
    'Account and password rows reuse existing routes with Back to settings',
    (tester) async {
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/settings',
      );
      await tester.tap(find.text('Chỉnh sửa hồ sơ'));
      await tester.pumpAndSettle();
      final router = container.read(appRouterProvider);
      expect(router.state.uri.path, '/profile/edit');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt lại mật khẩu'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/forgot-password');
      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/settings');
    },
  );

  testWidgets(
    'Confirmed logout retries errors and clears private stack and user state',
    (tester) async {
      final repo = ControlledAuth(user: authTestUser);
      final container = await mountAuth(tester, repo, route: '/profile/edit');
      final router = container.read(appRouterProvider);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Bản nháp bí mật',
      );
      container.read(favoriteIdsProvider.notifier).toggle('pho-demo');
      container.read(wantToVisitIdsProvider.notifier).toggle('pho-demo');
      unawaited(router.push('/settings'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(repo.signOuts, 0);
      repo.pendingSignOut = Completer<void>();
      await confirmLogout(tester);
      expect(repo.signOuts, 1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Đang đăng xuất…'), findsOneWidget);
      repo.pendingSignOut!.completeError(Exception('private SDK details'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không đăng xuất được. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(container.read(favoriteIdsProvider), {'pho-demo'});
      repo.pendingSignOut = null;
      await confirmLogout(tester);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/profile');
      expect(router.canPop(), isFalse);
      expect(find.text('Người thử nghiệm'), findsNothing);
      expect(container.read(favoriteIdsProvider), isEmpty);
      expect(container.read(wantToVisitIdsProvider), isEmpty);
      router.go('/my-reviews');
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/login');
      repo.setUser(authTestUser);
      await tester.pumpAndSettle();
      router.go('/profile/edit');
      await tester.pumpAndSettle();
      expect(find.text('Bản nháp bí mật'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        authTestUser.displayName,
      );
    },
  );

  testWidgets(
    'Confirmation for old account cannot sign out replacement account',
    (tester) async {
      final repo = ControlledAuth(user: authTestUser);
      await mountAuth(tester, repo, route: '/settings');
      await reveal(tester, find.text('Đăng xuất'));
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      repo.setUser(const UserProfile(id: 'b', displayName: 'Người khác'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Đăng xuất'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.signOuts, 0);
    },
  );

  testWidgets('Session loading and errors hide identity and support retry', (
    tester,
  ) async {
    final repo = ControlledAuth(initialReady: false);
    await mountAuth(tester, repo, route: '/settings');
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Đăng xuất'), findsNothing);
    repo.events.addError(Exception('private details'));
    await tester.pumpAndSettle();
    expect(find.text('Không kiểm tra được phiên đăng nhập.'), findsOneWidget);
    expect(find.text('private details'), findsNothing);
    repo.initialReady = true;
    repo.user = authTestUser;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text(authTestUser.displayName), findsOneWidget);
  });

  testWidgets(
    'Early guest event still clears private stack when signOut completes',
    (tester) async {
      final repo = ControlledAuth(user: authTestUser)
        ..pendingSignOut = Completer<void>();
      final container = await mountAuth(tester, repo, route: '/profile/edit');
      final router = container.read(appRouterProvider);
      unawaited(router.push('/settings'));
      await tester.pumpAndSettle();
      await confirmLogout(tester);
      repo.setUser(null);
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất'), findsNothing);
      repo.pendingSignOut!.complete();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/profile');
      expect(router.canPop(), isFalse);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      testWidgets(
        'Settings scroll and theme sheet fit $width $mode large text',
        (tester) async {
          await mountAuth(
            tester,
            ControlledAuth(user: authTestUser),
            route: '/settings',
            width: width,
            scale: 1.6,
            mode: mode,
          );
          await reveal(tester, find.text('Đăng xuất'));
          expect(tester.takeException(), isNull);
          await reveal(tester, find.text('Chế độ hiển thị'), delta: -250);
          await tester.tap(find.text('Chế độ hiển thị'));
          await tester.pumpAndSettle();
          expect(find.text('Hệ thống'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets('Render Settings $mode for visual comparison', (tester) async {
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/settings',
        mode: mode,
        height: 1260,
      );
      if (Platform.environment['CAPTURE_SETTINGS'] == '1') {
        final boundary =
            loginCaptureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/t20-stitch/flutter-${mode.name}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
    });
  }
}
