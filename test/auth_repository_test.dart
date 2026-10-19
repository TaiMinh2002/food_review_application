import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/auth/data/firebase_auth_repository.dart';
import 'package:food_review/features/auth/domain/auth_validation.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';

import 'support/auth_harness.dart';

class SdkUser extends Fake implements User {
  @override
  String get uid => 'sdk-user';
  @override
  String? get displayName => '  Tên hợp lệ  ';
  @override
  String? get photoURL => 'https://example.com/avatar.jpg';
}

class SdkCredential extends Fake implements UserCredential {}

class SdkAuth extends Fake implements FirebaseAuth {
  final changes = StreamController<User?>();
  String? email, password, failure;
  bool signedOut = false;
  @override
  Stream<User?> authStateChanges() => changes.stream;
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    this.email = email;
    this.password = password;
    if (failure != null) throw FirebaseAuthException(code: failure!);
    return SdkCredential();
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  test(
    'Adapter calls SDK, trims only email, maps stream to domain and signs out',
    () async {
      final sdk = SdkAuth();
      final repo = FirebaseAuthRepository(sdk);
      final users = repo.authStateChanges().toList();
      sdk.changes.add(null);
      sdk.changes.add(SdkUser());
      await sdk.changes.close();
      final values = await users;
      expect(values.first, isNull);
      expect(values.last?.id, 'sdk-user');
      expect(values.last?.displayName, 'Tên hợp lệ');
      await repo.signIn(email: ' a@example.com ', password: ' secret ');
      expect(sdk.email, 'a@example.com');
      expect(sdk.password, ' secret ');
      await repo.signOut();
      expect(sdk.signedOut, isTrue);
      sdk.failure = 'wrong-password';
      expect(
        () => repo.signIn(email: 'a@example.com', password: 'x'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'safe message',
            'Email hoặc mật khẩu không chính xác.',
          ),
        ),
      );
    },
  );
  test(
    'Authentication failures avoid account enumeration and raw SDK errors',
    () {
      for (final code in [
        'wrong-password',
        'user-not-found',
        'invalid-credential',
      ]) {
        expect(
          authFailure(code).message,
          'Email hoặc mật khẩu không chính xác.',
        );
      }
      expect(
        authFailure('network-request-failed').message,
        contains('Kiểm tra mạng'),
      );
      expect(authFailure('too-many-requests').message, contains('thử lại sau'));
      expect(
        authFailure('operation-not-allowed').message,
        contains('chưa sẵn sàng'),
      );
      expect(
        authFailure('secret-internal-sdk-details').message,
        isNot(contains('secret')),
      );
      expect(AuthValidation.email(' no-at '), isNotNull);
      expect(AuthValidation.email(' user@example.com '), isNull);
      expect(AuthValidation.password(''), isNotNull);
      expect(AuthValidation.password(' x '), isNull);
    },
  );
  test('Sign-in blocks duplicates, retains error, and ignores completion after disposal', () async {
    final repo = ControlledAuth()..pendingSignIn = Completer<void>();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    final subscription = container.listen(
      signInControllerProvider('route'),
      (_, _) {},
    );
    final controller = container.read(
      signInControllerProvider('route').notifier,
    );
    final pending = controller.submit(' test@example.com ', ' raw ');
    await controller.submit('duplicate', 'duplicate');
    expect(repo.signIns, 1);
    expect(repo.password, ' raw ');
    repo.pendingSignIn!.completeError(const AppException('Lỗi thử nghiệm'));
    await pending;
    expect(container.read(signInControllerProvider('route')).hasError, isTrue);
    repo.pendingSignIn = Completer<void>();
    final second = controller.submit('test@example.com', 'raw');
    subscription.close();
    container.dispose();
    repo.pendingSignIn!.complete();
    await second;
    await repo.events.close();
  });
  test(
    'Favorites clear on account switch/logout and guests cannot toggle',
    () async {
      final repo = ControlledAuth(user: authTestUser);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(() async {
        container.dispose();
        await repo.events.close();
      });
      final listen = container.listen(favoriteIdsProvider, (_, _) {});
      addTearDown(listen.close);
      await container.read(authSessionProvider.future);
      container.read(favoriteIdsProvider.notifier).toggle('pho-demo');
      expect(container.read(favoriteIdsProvider), {'pho-demo'});
      repo.setUser(const UserProfile(id: 'user-b', displayName: 'B'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(favoriteIdsProvider), isEmpty);
      container.read(favoriteIdsProvider.notifier).toggle('coffee-demo');
      repo.setUser(null);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(favoriteIdsProvider), isEmpty);
      expect(
        () => container.read(favoriteIdsProvider.notifier).toggle('pho-demo'),
        throwsA(isA<AppException>()),
      );
    },
  );
}
