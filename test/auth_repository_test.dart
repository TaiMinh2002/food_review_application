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
  String? updatedDisplayName;
  @override
  Future<void> updateDisplayName(String? displayName) async {
    updatedDisplayName = displayName;
  }
}

class SdkCredential extends Fake implements UserCredential {
  SdkCredential(this.user);
  @override
  final User? user;
}

class SdkAuth extends Fake implements FirebaseAuth {
  final changes = StreamController<User?>();
  String? email, password, failure;
  String? resetEmail;
  SdkUser? createdUser;
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
    return SdkCredential(null);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    this.email = email;
    this.password = password;
    if (failure != null) throw FirebaseAuthException(code: failure!);
    createdUser = SdkUser();
    return SdkCredential(createdUser);
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<void> sendPasswordResetEmail({
    ActionCodeSettings? actionCodeSettings,
    required String email,
  }) async {
    resetEmail = email;
    if (failure != null) throw FirebaseAuthException(code: failure!);
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
      await repo.signUp(
        displayName: '  Người dùng  ',
        email: ' register@example.com ',
        password: 'password',
      );
      expect(sdk.email, 'register@example.com');
      expect(sdk.password, 'password');
      expect(sdk.createdUser?.updatedDisplayName, 'Người dùng');
      await repo.resetPassword(email: ' reset@example.com ');
      expect(sdk.resetEmail, 'reset@example.com');
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
      sdk.failure = 'email-already-in-use';
      expect(
        () => repo.signUp(
          displayName: 'Người dùng',
          email: 'used@example.com',
          password: 'password',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'duplicate email message',
            contains('đã được đăng ký'),
          ),
        ),
      );
      sdk.failure = 'user-not-found';
      await repo.resetPassword(email: 'unknown@example.com');
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
      expect(AuthValidation.displayName(''), isNotNull);
      expect(AuthValidation.registrationPassword('short'), isNotNull);
      expect(AuthValidation.registrationPassword('password'), isNull);
      expect(
        AuthValidation.passwordConfirmation('different', 'password'),
        isNotNull,
      );
      expect(AuthValidation.terms(false), isNotNull);
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
