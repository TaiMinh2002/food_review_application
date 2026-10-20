import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/shared/widgets/app_bottom_navigation.dart';

import 'support/auth_harness.dart';

Future<void> openPicker(WidgetTester tester) async {
  final button = find.text('Thêm địa điểm vào danh sách');
  await tester.scrollUntilVisible(
    button,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAuthFonts);
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      testWidgets(
        'Editor and picker fit $width $mode large text and keyboard',
        (tester) async {
          await mountAuth(
            tester,
            ControlledAuth(user: authTestUser),
            route: '/collections/hanoi-demo/edit',
            mode: mode,
            width: width,
            scale: 1.6,
          );
          expect(find.byType(AppBottomNavigation), findsNothing);
          await openPicker(tester);
          expect(tester.takeException(), isNull);
          tester.view.viewInsets = const FakeViewPadding(bottom: 260);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final apply = find.text('Áp dụng (2 địa điểm)');
          expect(tester.getCenter(apply).dy, lessThan(844 - 260));
          await tester.tap(find.byTooltip('Đóng danh sách địa điểm'));
          await tester.pumpAndSettle();
          final save = find.byKey(const ValueKey('save-collection'));
          expect(tester.getCenter(save).dy, lessThan(844 - 260));
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets('Picker supports short viewport with keyboard in $mode', (
      tester,
    ) async {
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections/create',
        mode: mode,
        width: 320,
        height: 520,
        scale: 1.6,
      );
      await openPicker(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final apply = find.text('Áp dụng (0 địa điểm)');
      await tester.scrollUntilVisible(
        apply,
        150,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(tester.getCenter(apply).dy, lessThan(300));
    });
    testWidgets('Render edit form in $mode for Stitch comparison', (
      tester,
    ) async {
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections/hanoi-demo/edit',
        mode: mode,
        height: 1200,
      );
      if (Platform.environment['CAPTURE_COLLECTION_EDITOR'] == '1') {
        final boundary =
            loginCaptureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/t22-stitch/flutter-${mode.name}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
    });
  }
}
