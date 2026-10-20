import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/features/profile/domain/profile_repository.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';
import 'package:food_review/features/profile/presentation/profile_edit_controller.dart';

import 'support/auth_harness.dart';

class _Profiles implements ProfileRepository {
  int calls = 0;
  bool fail = false;
  Completer<void>? pending;
  void Function(UserProfile)? onSave;
  String? lastPhoto;

  @override
  Future<void> updateIdentity({
    required String userId,
    required String displayName,
    required String? photoUrl,
  }) async {
    calls++;
    lastPhoto = photoUrl;
    if (pending != null) await pending!.future;
    if (fail) {
      throw const AppException('Không lưu được hồ sơ. Vui lòng thử lại.');
    }
    onSave?.call(
      UserProfile(id: userId, displayName: displayName, photoUrl: photoUrl),
    );
  }
}

class _Photos implements ProfilePhotoRepository {
  int uploads = 0;
  bool fail = false;
  Completer<String>? pending;
  @override
  Future<ProfilePhoto?> pickPhoto() async => null;
  @override
  Future<String> uploadPhoto(ProfilePhoto photo) async {
    uploads++;
    if (fail) throw const AppException('Không tải được ảnh.');
    return pending?.future ?? Future.value('https://example.com/avatar.jpg');
  }
}

void main() {
  setUpAll(loadAuthFonts);

  test('Upload failure prevents save; retry reuses uploaded photo after write failure', () async {
    final profiles = _Profiles()..fail = true;
    final photos = _Photos()..fail = true;
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWithValue(const AsyncData(authTestUser)),
        profileRepositoryProvider.overrideWithValue(profiles),
        profilePhotoRepositoryProvider.overrideWithValue(photos),
      ],
    );
    addTearDown(container.dispose);
    final provider = profileEditControllerProvider(authTestUser.id);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);
    final controller = container.read(provider.notifier);
    final photo = ProfilePhoto(
      bytes: Uint8List.fromList([1]),
      name: 'avatar.jpg',
    );
    expect(
      await controller.save(
        displayName: 'New Name',
        photoUrl: null,
        newPhoto: photo,
      ),
      isFalse,
    );
    expect(profiles.calls, 0);
    photos.fail = false;
    expect(
      await controller.save(
        displayName: 'New Name',
        photoUrl: null,
        newPhoto: photo,
      ),
      isFalse,
    );
    profiles.fail = false;
    expect(
      await controller.save(
        displayName: 'New Name',
        photoUrl: null,
        newPhoto: photo,
      ),
      isTrue,
    );
    expect(photos.uploads, 2);
    expect(profiles.lastPhoto, 'https://example.com/avatar.jpg');
  });

  test(
    'Account switch during upload prevents writing the previous profile',
    () async {
      final auth = ControlledAuth(user: authTestUser);
      final profiles = _Profiles();
      final photos = _Photos()..pending = Completer<String>();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(profiles),
          profilePhotoRepositoryProvider.overrideWithValue(photos),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await auth.events.close();
      });
      final authSub = container.listen(authSessionProvider, (_, _) {});
      addTearDown(authSub.close);
      await container.read(authSessionProvider.future);
      final provider = profileEditControllerProvider(authTestUser.id);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(provider.notifier);
      final saving = controller.save(
        displayName: 'New',
        photoUrl: null,
        newPhoto: ProfilePhoto(
          bytes: Uint8List.fromList([1]),
          name: 'avatar.jpg',
        ),
      );
      expect(
        await controller.save(displayName: 'Duplicate', photoUrl: null),
        isFalse,
      );
      auth.setUser(const UserProfile(id: 'other', displayName: 'Other'));
      await Future<void>.delayed(Duration.zero);
      photos.pending!.complete('https://example.com/avatar.jpg');
      expect(await saving, isFalse);
      expect(profiles.calls, 0);
    },
  );

  for (final width in [320.0, 390.0, 428.0]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'Edit Profile fits $width ${mode.name} with large text and keyboard',
        (tester) async {
          await mountAuth(
            tester,
            ControlledAuth(user: authTestUser),
            route: '/profile/edit',
            width: width,
            scale: 1.6,
            mode: mode,
          );
          expect(find.text('Edit Profile'), findsOneWidget);
          await tester.tap(find.byType(TextFormField).first);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Lưu thay đổi'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Validation, failed save, retry and cancel preserve profile state',
    (tester) async {
      final auth = ControlledAuth(user: authTestUser);
      final profiles = _Profiles()
        ..fail = true
        ..onSave = auth.setUser;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(auth.events.close);
      final scoped = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          profileRepositoryProvider.overrideWithValue(profiles),
        ],
      );
      addTearDown(scoped.dispose);
      await _mountScoped(tester, scoped);
      await tester.tap(find.text('Chỉnh sửa hồ sơ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lưu thay đổi'));
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(profiles.calls, 0);
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập tên hiển thị.'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, 'Tên mới');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Lưu thay đổi'));
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không lưu được hồ sơ. Vui lòng thử lại.'),
        findsOneWidget,
      );
      profiles.fail = false;
      await tester.ensureVisible(find.text('Lưu thay đổi'));
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(scoped.read(appRouterProvider).state.uri.path, '/profile');
      expect(find.text('Tên mới'), findsOneWidget);
      await tester.tap(find.text('Chỉnh sửa hồ sơ'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Không lưu');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ thay đổi').last);
      await tester.pumpAndSettle();
      expect(profiles.calls, 2);
      expect(find.text('Tên mới'), findsOneWidget);
      scoped.read(appRouterProvider).go('/profile/edit');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(scoped.read(appRouterProvider).state.uri.path, '/profile');
    },
  );

  testWidgets('Capture Edit Profile for Stitch comparison', (tester) async {
    await mountAuth(
      tester,
      ControlledAuth(user: authTestUser),
      route: '/profile/edit',
    );
    final boundary =
        loginCaptureKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final rendered = await boundary.toImage(pixelRatio: 2);
      final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
      await Directory('/tmp/t18-stitch').create(recursive: true);
      await File('/tmp/t18-stitch/flutter-edit.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      rendered.dispose();
    });
  });
}

Future<void> _mountScoped(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container.read(appRouterProvider).go('/profile');
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FoodReviewApp(),
    ),
  );
  await tester.pumpAndSettle();
}
