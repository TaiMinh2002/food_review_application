import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/notifications/domain/notification_repository.dart';
import 'package:food_review/features/notifications/presentation/notifications_controller.dart';

import 'support/auth_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAuthFonts);

  testWidgets(
    'marks one notification read and opens only its typed internal target',
    (tester) async {
      final repository = _Notifications();
      final auth = ControlledAuth(user: authTestUser);
      final container = await mountAuth(
        tester,
        auth,
        route: '/notifications',
        notifications: repository,
      );
      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Đánh giá đã được phê duyệt'), findsOneWidget);
      if (Platform.environment['CAPTURE_NOTIFICATIONS'] == '1') {
        final boundary =
            loginCaptureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/t23-stitch/flutter-light.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byKey(const ValueKey('notification-approved')));
      await tester.pumpAndSettle();
      expect(repository.readIds, contains('approved'));
      expect(container.read(notificationsControllerProvider).unreadCount, 1);
      expect(find.text('Bánh Mì Buổi Sáng'), findsOneWidget);
    },
  );

  testWidgets(
    'marks all read, retains per-user data, and handles empty and error states',
    (tester) async {
      final repository = _Notifications();
      final auth = ControlledAuth(user: authTestUser);
      final container = await mountAuth(
        tester,
        auth,
        route: '/notifications',
        notifications: repository,
      );
      await tester.tap(find.byTooltip('Đánh dấu đã đọc'));
      await tester.pumpAndSettle();
      expect(repository.markAllCalls, 1);
      expect(container.read(notificationsControllerProvider).unreadCount, 0);

      repository.items.clear();
      await container.read(notificationsControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Bạn chưa có thông báo nào'), findsOneWidget);

      repository.fail = true;
      await container.read(notificationsControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    },
  );

  testWidgets('is usable at narrow large-text and dark layouts', (
    tester,
  ) async {
    final auth = ControlledAuth(user: authTestUser);
    await mountAuth(
      tester,
      auth,
      route: '/notifications',
      width: 320,
      height: 520,
      scale: 1.6,
      mode: ThemeMode.dark,
      notifications: _Notifications(),
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    if (Platform.environment['CAPTURE_NOTIFICATIONS'] == '1') {
      final boundary =
          loginCaptureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('/tmp/t23-stitch/flutter-dark.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the demo inbox for Stitch comparison', (tester) async {
    await mountAuth(
      tester,
      ControlledAuth(user: authTestUser),
      route: '/notifications',
      height: 960,
    );
    if (Platform.environment['CAPTURE_NOTIFICATIONS'] == '1') {
      final boundary =
          loginCaptureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('/tmp/t23-stitch/flutter-demo.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(find.text('Đánh giá nhận được lượt hữu ích'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Notifications implements NotificationRepository {
  final items = <AppNotification>[
    AppNotification(
      id: 'approved',
      recipientId: authTestUser.id,
      kind: AppNotificationKind.approved,
      title: 'Đánh giá đã được phê duyệt',
      message: 'Bánh Mì 25 đã được duyệt.',
      createdAt: DateTime.now(),
      targetType: NotificationTargetType.restaurant,
      targetId: 'banh-mi-demo',
    ),
    AppNotification(
      id: 'welcome',
      recipientId: authTestUser.id,
      kind: AppNotificationKind.welcome,
      title: 'Chào mừng',
      message: 'Cảm ơn bạn.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
  final readIds = <String>[];
  var markAllCalls = 0;
  var fail = false;
  @override
  bool get isDemo => true;

  @override
  Future<NotificationPage> getNotifications({
    required String recipientId,
    String? cursor,
    int limit = 20,
  }) async {
    if (fail) throw const AppException('Lỗi mô phỏng');
    final owned = items
        .where((item) => item.recipientId == recipientId)
        .toList();
    return NotificationPage(items: owned, total: owned.length, isDemo: true);
  }

  @override
  Future<void> markAllRead({required String recipientId}) async {
    markAllCalls++;
    for (var index = 0; index < items.length; index++) {
      if (items[index].recipientId == recipientId) {
        items[index] = items[index].copyWith(readAt: DateTime.now());
      }
    }
  }

  @override
  Future<void> markRead({
    required String recipientId,
    required String id,
  }) async {
    readIds.add(id);
    final index = items.indexWhere(
      (item) => item.id == id && item.recipientId == recipientId,
    );
    if (index >= 0) {
      items[index] = items[index].copyWith(readAt: DateTime.now());
    }
  }
}
