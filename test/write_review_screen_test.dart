import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/reviews/domain/review.dart';
import 'package:food_review/features/reviews/domain/review_repository.dart';
import 'package:food_review/shared/widgets/app_button.dart';

import 'support/auth_harness.dart';

class _WriteRepository implements ReviewRepository {
  final created = <Review>[];
  @override
  Future<void> create(Review review) async => created.add(review);

  @override
  Stream<List<Review>> watchForPlace(String placeId, {int limit = 20}) =>
      Stream.value(
        created
            .where((review) => review.placeId == placeId)
            .take(limit)
            .toList(),
      );
}

void main() {
  setUpAll(loadAuthFonts);

  Finder submit() => find.widgetWithText(AppButton, 'Gửi đánh giá');

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      testWidgets('Write review fits $width in ${mode.name}', (tester) async {
        await mountAuth(
          tester,
          ControlledAuth(user: authTestUser),
          route: '/restaurants/pho-demo/reviews/create',
          width: width,
          height: 844,
          scale: 1.6,
          mode: mode,
        );
        await tester.pumpAndSettle();
        expect(find.text('Bạn đánh giá quán thế nào?'), findsOneWidget);
        await tester.ensureVisible(submit());
        expect(submit().hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Rating, tags and validation stay local to the draft', (
    tester,
  ) async {
    await mountAuth(
      tester,
      ControlledAuth(user: authTestUser),
      route: '/restaurants/pho-demo/reviews/create',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).last);
    await tester.pump();
    expect(find.text('Xuất sắc tuyệt vời'), findsOneWidget);
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(find.text('Hãy chia sẻ ít nhất 10 ký tự.'), findsOneWidget);
    await tester.tap(find.text('+ Nước dùng thanh ngọt'));
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('review-content')),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      'Nước dùng thanh ngọt',
    );
  });

  testWidgets('Successful review preserves place and returns to the source', (
    tester,
  ) async {
    final repo = _WriteRepository();
    final container = await mountAuth(
      tester,
      ControlledAuth(user: authTestUser),
      route: '/restaurants/pho-demo/reviews',
      reviews: repo,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viết đánh giá của bạn'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_border).last);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('review-content')),
      'Nước dùng thanh và thịt bò mềm, phục vụ nhanh.',
    );
    await tester.tap(submit());
    await tester.pumpAndSettle();
    expect(repo.created, hasLength(1));
    expect(repo.created.single.placeId, 'pho-demo');
    expect(repo.created.single.userId, authTestUser.id);
    expect(
      container.read(appRouterProvider).state.uri.path,
      '/restaurants/pho-demo/reviews',
    );
  });

  if (const bool.fromEnvironment('WRITE_REVIEW_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture Write Review ${mode.name}', (tester) async {
        await mountAuth(
          tester,
          ControlledAuth(user: authTestUser),
          route: '/restaurants/pho-demo/reviews/create',
          height: 884,
          mode: mode,
        );
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(loginCaptureKey),
        )..markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/write-review-screenshots')
              .createSync(recursive: true);
          File('build/write-review-screenshots/write-review-${mode.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
