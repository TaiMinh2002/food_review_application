import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/shared/widgets/app_button.dart';

import 'support/auth_harness.dart';

void main() {
  setUpAll(loadAuthFonts);

  Finder submit() => find.widgetWithText(AppButton, 'Đăng ký');

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'Register fits $width at ${scale}x in ${mode.name} with keyboard',
          (tester) async {
            await mountAuth(
              tester,
              ControlledAuth(),
              route: '/register',
              width: width,
              scale: scale,
              mode: mode,
            );
            await tester.ensureVisible(submit());
            expect(find.byType(NavigationBar), findsNothing);
            expect(tester.takeException(), isNull);
            await fillRegister(tester, acceptTerms: false);
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            addTearDown(tester.view.resetViewInsets);
            await tester.pumpAndSettle();
            await tester.ensureVisible(submit());
            expect(submit().hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'Register validation prevents request and shows terms/password errors',
    (tester) async {
      final repo = ControlledAuth();
      await mountAuth(tester, repo, route: '/register');
      await tester.tap(submit());
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập tên hiển thị.'), findsOneWidget);
      expect(find.text('Vui lòng nhập địa chỉ email hợp lệ.'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
      expect(find.text('Vui lòng xác nhận mật khẩu.'), findsOneWidget);
      expect(
        find.text('Vui lòng đồng ý với điều khoản để tiếp tục.'),
        findsOneWidget,
      );
      expect(repo.signUps, 0);
    },
  );

  testWidgets(
    'Register submits once, keeps context, and navigates after success',
    (tester) async {
      final repo = ControlledAuth()..autoSignUp = true;
      const target = '/restaurants/pho-demo/reviews/create';
      final container = await mountAuth(
        tester,
        repo,
        route: Uri(
          path: '/register',
          queryParameters: {'returnTo': target, 'action': 'favorite'},
        ).toString(),
      );
      await fillRegister(tester);
      await tester.tap(submit());
      await tester.pumpAndSettle();
      expect(repo.signUps, 1);
      expect(repo.email, 'tester@example.com');
      expect(repo.displayName, 'Người dùng thử');
      expect(
        container.read(appRouterProvider).state.uri.path,
        '/restaurants/pho-demo/reviews/create',
      );
    },
  );

  testWidgets('Register failure retains fields and permits retry', (
    tester,
  ) async {
    final repo = ControlledAuth()..pendingSignUp = Completer<void>();
    await mountAuth(tester, repo, route: '/register');
    await fillRegister(tester);
    await tester.tap(submit());
    await tester.pump();
    expect(repo.signUps, 1);
    expect(submit().hitTestable(), findsNothing);
    repo.pendingSignUp!.completeError(StateError('registration failed'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không tạo được tài khoản. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(find.text('Người dùng thử'), findsOneWidget);
    repo.pendingSignUp = null;
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(repo.signUps, 2);
  });

  testWidgets('Login link preserves registration context', (tester) async {
    final container = await mountAuth(
      tester,
      ControlledAuth(),
      route: '/register?returnTo=%2Fhome&action=favorite',
    );
    await tester.ensureVisible(find.text('Đăng nhập'));
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    final uri = container.read(appRouterProvider).state.uri;
    expect(uri.path, '/login');
    expect(uri.queryParameters['returnTo'], '/home');
    expect(uri.queryParameters['action'], 'favorite');
  });

  if (const bool.fromEnvironment('REGISTER_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture Register ${mode.name}', (tester) async {
        await mountAuth(
          tester,
          ControlledAuth(),
          route: '/register',
          height: 884,
          mode: mode,
        );
        tester
            .renderObject<RenderRepaintBoundary>(find.byKey(loginCaptureKey))
            .markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(loginCaptureKey))
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/register-screenshots').createSync(recursive: true);
          File('build/register-screenshots/register-${mode.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
