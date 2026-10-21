import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/places/data/demo_place_repository.dart';
import 'package:food_review/features/profile/domain/profile_repository.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';
import 'package:food_review/features/reports/data/demo_report_repository.dart';
import 'package:food_review/features/reports/domain/report_repository.dart';
import 'package:food_review/features/reviews/data/demo_review_repository.dart';
import 'package:food_review/features/reviews/domain/review.dart';

import 'support/auth_harness.dart';

const target = (
  type: ReportTargetType.review,
  id: 'review-linh-demo',
  placeId: 'pho-demo',
);
const route =
    '/reports/create?targetType=review&restaurantId=pho-demo&reviewId=review-linh-demo';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAuthFonts);
  test('target parser rejects ambiguous/missing identifiers and supports current place/user links', () {
    expect(parseReportTarget(Uri.parse(route)), target);
    expect(
      parseReportTarget(
        Uri.parse('/reports/create?targetType=place&restaurantId=pho-demo'),
      )?.id,
      'pho-demo',
    );
    expect(
      parseReportTarget(
        Uri.parse('/reports/create?targetType=user&userId=linh-demo'),
      )?.type,
      ReportTargetType.user,
    );
    for (final bad in [
      '/reports/create',
      '/reports/create?targetType=review&reviewId=a',
      '$route&userId=b',
      '$route&reviewId=other',
      '/reports/create?targetType=user&userId=%20',
      '/reports/create?targetType=user&userId=a%2Fb',
    ]) {
      expect(parseReportTarget(Uri.parse(bad)), isNull, reason: bad);
    }
  });

  test('demo submission validates, scopes retries and commits once under concurrency', () async {
    final reviews = DemoReviewRepository();
    addTearDown(reviews.dispose);
    final repo = DemoReportRepository(
      places: DemoPlaceRepository(),
      reviews: reviews,
    );
    final draft = ReportDraft(
      target: target,
      reason: ReportReason.spam,
      description: '  Nội dung thử  ',
    );
    final receipts = await Future.wait([
      for (var i = 0; i < 2; i++)
        repo.submit(reporterId: 'a', requestId: 'same', draft: draft),
    ]);
    expect(receipts[0].id, receipts[1].id);
    expect(receipts.first.isDemo, isTrue);
    expect(
      (await repo.submit(reporterId: 'b', requestId: 'same', draft: draft)).id,
      isNot(receipts.first.id),
    );
    await expectLater(
      repo.submit(
        reporterId: 'a',
        requestId: 'same',
        draft: ReportDraft(
          target: target,
          reason: ReportReason.other,
          description: '',
        ),
      ),
      throwsA(isA<AppException>()),
    );
    expect(
      ReportDraft(
        target: target,
        reason: ReportReason.spam,
        description: 'a' * 501,
      ).validationError,
      isNotNull,
    );
    expect(
      validateReportEvidence(
        ReportEvidence(bytes: Uint8List(0), name: 'empty'),
      ),
      isNotNull,
    );
    expect(
      validateReportEvidence(
        ReportEvidence(bytes: Uint8List.fromList([1, 2, 3]), name: 'fake.jpg'),
      ),
      isNotNull,
    );
    expect(
      (await repo.getTarget((
        type: ReportTargetType.review,
        id: 'review-linh-demo',
        placeId: 'coffee-demo',
      ), reporterId: 'a')),
      isNull,
    );
  });

  test('private review targets are not exposed to another reporter and deleted targets cannot submit', () async {
    final reviews = DemoReviewRepository();
    addTearDown(reviews.dispose);
    await reviews.create(
      Review(
        id: 'private',
        placeId: 'pho-demo',
        userId: 'a',
        rating: 4,
        content: 'Nội dung chưa được xuất bản công khai.',
        createdAt: DateTime.now(),
      ),
    );
    final repo = DemoReportRepository(
      places: DemoPlaceRepository(),
      reviews: reviews,
    );
    const privateTarget = (
      type: ReportTargetType.review,
      id: 'private',
      placeId: 'pho-demo',
    );
    expect(await repo.getTarget(privateTarget, reporterId: 'b'), isNull);
    expect(await repo.getTarget(privateTarget, reporterId: 'a'), isNotNull);
    await reviews.delete(userId: 'a', placeId: 'pho-demo', reviewId: 'private');
    await expectLater(
      repo.submit(
        reporterId: 'a',
        requestId: 'deleted',
        draft: ReportDraft(
          target: privateTarget,
          reason: ReportReason.other,
          description: '',
        ),
      ),
      throwsA(isA<AppException>()),
    );
    expect(
      ReportDraft(
        target: target,
        reason: ReportReason.other,
        description: '👩‍💻' * 500,
      ).validationError,
      isNull,
    );
    expect(
      ReportDraft(
        target: target,
        reason: ReportReason.other,
        description: '',
        evidence: List.generate(
          4,
          (_) => ReportEvidence(
            bytes: Uint8List.fromList([255, 216, 255]),
            name: 'x.jpg',
          ),
        ),
      ).validationError,
      isNotNull,
    );
  });

  for (final item in [
    (
      '/reports/create?targetType=place&restaurantId=pho-demo',
      'Quán ăn',
      'Phở Nhà Mình',
    ),
    (
      '/reports/create?targetType=user&userId=linh-demo',
      'Người dùng',
      'Hoàng Linh',
    ),
  ]) {
    testWidgets('loads exact ${item.$2} report context', (tester) async {
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: item.$1,
      );
      expect(find.text(item.$2), findsOneWidget);
      expect(find.text(item.$3), findsOneWidget);
      expect(
        tester
            .widget<RadioGroup<ReportReason>>(
              find.byType(RadioGroup<ReportReason>),
            )
            .groupValue,
        isNull,
      );
    });
  }

  testWidgets(
    'reason is required; failure preserves draft and retry reuses request ID without duplicate submit',
    (tester) async {
      final repo = _Reports();
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: route,
        reports: repo,
      );
      await reveal(tester, find.text('Gửi báo cáo'));
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pumpAndSettle();
      expect(repo.requests, isEmpty);
      expect(find.text('Vui lòng chọn lý do báo cáo.'), findsOneWidget);
      await reveal(tester, find.text('Spam hoặc quảng cáo'));
      await tester.tap(find.text('Spam hoặc quảng cáo'));
      await reveal(tester, find.byType(TextFormField));
      await tester.enterText(
        find.byType(TextFormField),
        'Mô tả báo cáo thử nghiệm',
      );
      repo.pending = Completer<ReportReceipt>();
      await reveal(tester, find.text('Gửi báo cáo'));
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pump();
      expect(repo.requests.length, 1);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(repo.requests.length, 1);
      expect(find.text('Đã lưu báo cáo minh họa'), findsNothing);
      repo.pending!.completeError(const AppException('Lỗi gửi mô phỏng.'));
      await tester.pumpAndSettle();
      expect(find.text('Lỗi gửi mô phỏng.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'Mô tả báo cáo thử nghiệm',
      );
      repo.pending = null;
      await reveal(tester, find.text('Gửi báo cáo'));
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pumpAndSettle();
      expect(repo.requests.length, 2);
      expect(repo.requests.toSet().length, 1);
      expect(find.text('Đã lưu báo cáo minh họa'), findsOneWidget);
    },
  );

  testWidgets('Cancel/system Back keeps or discards draft and never submits', (
    tester,
  ) async {
    final repo = _Reports();
    final container = await mountAuth(
      tester,
      ControlledAuth(user: authTestUser),
      route: route,
      reports: repo,
    );
    await tester.tap(find.text('Thông tin sai sự thật'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bỏ báo cáo đang soạn?'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục soạn'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Hủy bỏ'));
    await tester.tap(find.text('Hủy bỏ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ báo cáo'));
    await tester.pumpAndSettle();
    expect(container.read(appRouterProvider).state.uri.path, '/home');
    expect(repo.requests, isEmpty);
  });

  testWidgets(
    'evidence selection handles duplicate, remove, format error and three-photo limit without upload',
    (tester) async {
      final photos = _Photos();
      for (final asset in ['pho', 'coffee', 'banh_mi']) {
        final bytes = await rootBundle.load('assets/images/demo/$asset.jpg');
        photos.queue.add(
          ProfilePhoto(bytes: bytes.buffer.asUint8List(), name: '$asset.jpg'),
        );
      }
      final first = photos.queue.first;
      photos.queue.insert(1, first);
      final repo = _Reports();
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: route,
        reports: repo,
        reportPhotos: photos,
      );
      for (var i = 0; i < 4; i++) {
        await reveal(tester, find.text('Thêm ảnh'));
        await tester.tap(find.text('Thêm ảnh'));
        await tester.pumpAndSettle();
      }
      expect(find.byTooltip('Xóa ảnh minh chứng 3'), findsOneWidget);
      final add = find.ancestor(
        of: find.text('Thêm ảnh'),
        matching: find.byType(OutlinedButton),
      );
      expect(tester.widget<OutlinedButton>(add).onPressed, isNull);
      await tester.tap(find.byTooltip('Xóa ảnh minh chứng 2'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Xóa ảnh minh chứng 3'), findsNothing);
      photos.queue.add(
        ProfilePhoto(bytes: Uint8List.fromList([1, 2, 3]), name: 'bad.jpg'),
      );
      await tester.tap(find.text('Thêm ảnh'));
      await tester.pumpAndSettle();
      expect(
        find.text('Vui lòng chọn ảnh định dạng JPG hoặc PNG.'),
        findsOneWidget,
      );
      expect(photos.uploads, 0);
    },
  );

  testWidgets(
    'account switch clears draft and ignores late submit; invalid/missing/error targets are safe',
    (tester) async {
      final repo = _Reports();
      final auth = ControlledAuth(user: authTestUser);
      final container = await mountAuth(
        tester,
        auth,
        route: route,
        reports: repo,
      );
      await tester.tap(find.text('Thông tin sai sự thật'));
      repo.pending = Completer<ReportReceipt>();
      await reveal(tester, find.text('Gửi báo cáo'));
      await tester.tap(find.text('Gửi báo cáo'));
      await tester.pump();
      auth.setUser(const UserProfile(id: 'b', displayName: 'B'));
      await tester.pumpAndSettle();
      repo.pending!.complete(const ReportReceipt(id: 'late', isDemo: true));
      await tester.pumpAndSettle();
      expect(find.text('Đã lưu báo cáo minh họa'), findsNothing);
      expect(
        tester
            .widget<RadioGroup<ReportReason>>(
              find.byType(RadioGroup<ReportReason>),
            )
            .groupValue,
        isNull,
      );
      final router = container.read(appRouterProvider);
      router.go('/reports/create');
      await tester.pumpAndSettle();
      expect(find.text('Không thể mở báo cáo'), findsOneWidget);
      repo.missing = true;
      router.go(route);
      await tester.pumpAndSettle();
      expect(find.textContaining('Nội dung không tồn tại'), findsOneWidget);
      repo.missing = false;
      repo.loadFail = true;
      router.go('/home');
      await tester.pumpAndSettle();
      router.go(route);
      await tester.pumpAndSettle();
      expect(find.text('Thử lại'), findsOneWidget);
      repo.loadFail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Lý do báo cáo *'), findsOneWidget);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      testWidgets('report fits $width $mode large text and keyboard', (
        tester,
      ) async {
        await mountAuth(
          tester,
          ControlledAuth(user: authTestUser),
          route: route,
          width: width,
          height: 700,
          scale: 1.6,
          mode: mode,
          keyboard: 240,
        );
        expect(tester.takeException(), isNull);
        await reveal(tester, find.byType(TextFormField));
        await tester.enterText(
          find.byType(TextFormField),
          'Nội dung có dấu tiếng Việt',
        );
        await reveal(tester, find.text('Gửi báo cáo'));
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('capture report $mode for Stitch', (tester) async {
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: route,
        height: 1650,
        mode: mode,
      );
      if (Platform.environment['CAPTURE_REPORT'] == '1') {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();
        final boundary =
            loginCaptureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/t25-stitch/flutter-${mode.name}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
    });
  }
}

class _Reports implements ReportRepository {
  final requests = <String>[];
  bool missing = false, loadFail = false;
  Completer<ReportReceipt>? pending;
  @override
  bool get isDemo => true;
  @override
  Future<ReportContext?> getTarget(
    ReportTarget target, {
    required String reporterId,
  }) async {
    if (loadFail) throw const AppException('Lỗi tải mô phỏng.');
    return missing
        ? null
        : ReportContext(
            target: target,
            title: 'Quán mẫu',
            authorName: 'Hoàng Linh',
            excerpt: 'Nội dung đánh giá mẫu',
          );
  }

  @override
  Future<ReportReceipt> submit({
    required String reporterId,
    required String requestId,
    required ReportDraft draft,
  }) async {
    requests.add(requestId);
    return pending?.future ??
        Future.value(const ReportReceipt(id: 'example', isDemo: true));
  }
}

class _Photos implements ProfilePhotoRepository {
  final queue = <ProfilePhoto>[];
  int uploads = 0;
  @override
  Future<ProfilePhoto?> pickPhoto() async =>
      queue.isEmpty ? null : queue.removeAt(0);
  @override
  Future<String> uploadPhoto(ProfilePhoto photo) async {
    uploads++;
    throw UnimplementedError();
  }
}
