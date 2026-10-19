import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/shared/widgets/app_button.dart';

import 'support/auth_harness.dart';

void main() {
  setUpAll(loadAuthFonts);

  Finder submit() => find.widgetWithText(AppButton, 'Gửi hướng dẫn đặt lại');
  Finder email() => find.byKey(const ValueKey('forgot-email'));

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'Forgot password fits $width at ${scale}x in ${mode.name}',
          (tester) async {
            await mountAuth(
              tester,
              ControlledAuth(),
              route: '/forgot-password',
              width: width,
              scale: scale,
              mode: mode,
            );
            expect(find.byType(NavigationBar), findsNothing);
            await tester.ensureVisible(submit());
            expect(submit().hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('Invalid email does not send and keeps validation local', (
    tester,
  ) async {
    final repo = ControlledAuth();
    await mountAuth(tester, repo, route: '/forgot-password');
    await tester.enterText(
      find.descendant(of: email(), matching: find.byType(TextFormField)),
      'invalid',
    );
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập địa chỉ email hợp lệ.'), findsOneWidget);
    expect(repo.resetRequests, 0);
  });

  testWidgets(
    'Reset request shows generic success and prevents duplicate sends',
    (tester) async {
      final repo = ControlledAuth()..pendingReset = Completer<void>();
      await mountAuth(tester, repo, route: '/forgot-password');
      await tester.enterText(
        find.descendant(of: email(), matching: find.byType(TextFormField)),
        ' tester@example.com ',
      );
      await tester.tap(submit());
      await tester.pump();
      expect(repo.resetRequests, 1);
      expect(repo.resetEmail, 'tester@example.com');
      expect(submit(), findsNothing);
      repo.pendingReset!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Kiểm tra email của bạn'), findsOneWidget);
      expect(find.text('Gửi lại hoặc thử email khác'), findsOneWidget);
      await tester.tap(find.text('Gửi lại hoặc thử email khác'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập địa chỉ email của bạn'), findsOneWidget);
    },
  );

  testWidgets('Reset failure retains input and can retry', (tester) async {
    final repo = ControlledAuth()..pendingReset = Completer<void>();
    await mountAuth(tester, repo, route: '/forgot-password');
    await tester.enterText(
      find.descendant(of: email(), matching: find.byType(TextFormField)),
      'tester@example.com',
    );
    await tester.tap(submit());
    await tester.pump();
    repo.pendingReset!.completeError(StateError('network'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không gửi được hướng dẫn. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<EditableText>(find.byType(EditableText))
          .single
          .controller
          .text,
      'tester@example.com',
    );
    repo.pendingReset = null;
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(repo.resetRequests, 2);
    expect(find.text('Kiểm tra email của bạn'), findsOneWidget);
  });

  testWidgets('Login links preserve return-to and action context', (
    tester,
  ) async {
    final container = await mountAuth(
      tester,
      ControlledAuth(),
      route: '/forgot-password?returnTo=%2Fhome&action=favorite',
    );
    await tester.ensureVisible(find.text('Đăng nhập'));
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    final uri = container.read(appRouterProvider).state.uri;
    expect(uri.path, '/login');
    expect(uri.queryParameters['returnTo'], '/home');
    expect(uri.queryParameters['action'], 'favorite');
  });

  if (const bool.fromEnvironment('FORGOT_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture Forgot Password ${mode.name}', (tester) async {
        await mountAuth(
          tester,
          ControlledAuth(),
          route: '/forgot-password',
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
          Directory('build/forgot-screenshots').createSync(recursive: true);
          File('build/forgot-screenshots/forgot-${mode.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
