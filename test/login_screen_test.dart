import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/shared/widgets/app_button.dart';

import 'support/auth_harness.dart';

void main() {
  setUpAll(loadAuthFonts);
  Finder submit() => find.widgetWithText(AppButton, 'Đăng nhập');
  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.ensureVisible(submit());
    await tester.tap(submit());
    await tester.pump();
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'Login fits $width at ${scale}x in ${mode.name} with keyboard',
          (tester) async {
            await mountAuth(
              tester,
              ControlledAuth(),
              width: width,
              scale: scale,
              mode: mode,
            );
            expect(find.byType(NavigationBar), findsNothing);
            await tester.ensureVisible(find.text('Đăng ký ngay'));
            expect(tester.takeException(), isNull);
            await fillLogin(tester);
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
    'Validation makes no request; password visibility and failed retry retain input',
    (tester) async {
      final repo = ControlledAuth()..pendingSignIn = Completer<void>();
      await mountAuth(tester, repo);
      await tapSubmit(tester);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập địa chỉ email hợp lệ.'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu.'), findsOneWidget);
      expect(repo.signIns, 0);
      await fillLogin(tester);
      await tester.ensureVisible(find.byTooltip('Hiện mật khẩu'));
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .obscureText,
        isFalse,
      );
      await tapSubmit(tester);
      expect(repo.signIns, 1);
      expect(repo.email, 'tester@example.com');
      expect(repo.password, ' secret ');
      // No duplicate submission while the repository call is still pending.
      expect(
        tester.widget<AppButton>(find.byType(AppButton).first).isLoading,
        isTrue,
      );
      await tester.tap(find.byType(AppButton).first);
      await tester.pump();
      expect(repo.signIns, 1);
      repo.pendingSignIn!.completeError(
        const AppException('Email hoặc mật khẩu không chính xác.'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Email hoặc mật khẩu không chính xác.'), findsOneWidget);
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .controller
            .text,
        ' secret ',
      );
      repo.pendingSignIn = null;
      repo.autoSignIn = true;
      await tapSubmit(tester);
      await tester.pumpAndSettle();
      expect(find.text('Trang Chủ'), findsOneWidget);
    },
  );
  testWidgets(
    'Register/forgot links preserve return-to and cancel restores login draft',
    (tester) async {
      const target = '/restaurants/pho-demo/reviews/create';
      final container = await mountAuth(
        tester,
        ControlledAuth(),
        route: Uri(
          path: '/login',
          queryParameters: {'returnTo': target},
        ).toString(),
      );
      await fillLogin(tester);
      for (final link in ['Quên mật khẩu?', 'Đăng ký ngay']) {
        await tester.ensureVisible(find.text(link));
        await tester.tap(find.text(link));
        await tester.pumpAndSettle();
        expect(
          container
              .read(appRouterProvider)
              .state
              .uri
              .queryParameters['returnTo'],
          target,
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .last
              .controller
              .text,
          ' secret ',
        );
      }
    },
  );
  testWidgets(
    'Session error is retryable and does not enable login against unknown state',
    (tester) async {
      final repo = ControlledAuth();
      final container = await mountAuth(tester, repo);
      repo.events.addError(const AppException('Phiên lỗi thử nghiệm'));
      await tester.pumpAndSettle();
      expect(find.text('Phiên lỗi thử nghiệm'), findsOneWidget);
      expect(tester.widget<AppButton>(submit()).onPressed, isNull);
      await tester.tap(find.text('Thử lại phiên đăng nhập'));
      await tester.pumpAndSettle();
      expect(container.read(authSessionProvider).hasError, isFalse);
    },
  );
  if (const bool.fromEnvironment('LOGIN_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture Login ${mode.name}', (tester) async {
        await mountAuth(tester, ControlledAuth(), height: 884, mode: mode);
        tester
            .renderObject<RenderRepaintBoundary>(find.byKey(loginCaptureKey))
            .markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(loginCaptureKey))
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/login-screenshots').createSync(recursive: true);
          File('build/login-screenshots/login-${mode.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
