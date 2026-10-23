import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/auth/data/firebase_auth_repository.dart';
import 'package:food_review/features/profile/data/firebase_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSdkUser extends Fake implements User {
  @override
  String get uid => 'sdk-user';
  @override
  String? get displayName => updatedDisplayName ?? 'Tên hợp lệ';
  @override
  String? get photoURL => updatedPhoto ?? 'https://example.com/avatar.jpg';
  String? updatedDisplayName;
  String? updatedPhoto;
  String? profileFailure;

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    if (profileFailure != null) {
      throw FirebaseAuthException(code: profileFailure!);
    }
    updatedDisplayName = displayName;
    updatedPhoto = photoURL;
  }

  @override
  Future<void> updateDisplayName(String? displayName) async {
    updatedDisplayName = displayName;
  }
}

class _FakeCredential extends Fake implements UserCredential {
  _FakeCredential(this.user);
  @override
  final User? user;
}

class _FakeSdkAuth extends Fake implements FirebaseAuth {
  _FakeSdkUser? createdUser;

  @override
  User? get currentUser => createdUser;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    createdUser = _FakeSdkUser();
    return _FakeCredential(createdUser);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesThemeRepository unit tests', () {
    test('Defaults to system when no value stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SharedPreferencesThemeRepository(prefs);

      expect(repository.getThemeMode(), ThemeMode.system);
    });

    test('Loads dark and light from stored preferences', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
      final prefsDark = await SharedPreferences.getInstance();
      final repoDark = SharedPreferencesThemeRepository(prefsDark);
      expect(repoDark.getThemeMode(), ThemeMode.dark);

      SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
      final prefsLight = await SharedPreferences.getInstance();
      final repoLight = SharedPreferencesThemeRepository(prefsLight);
      expect(repoLight.getThemeMode(), ThemeMode.light);

      SharedPreferences.setMockInitialValues({
        'app_theme_mode': 'unknown_value',
      });
      final prefsInvalid = await SharedPreferences.getInstance();
      final repoInvalid = SharedPreferencesThemeRepository(prefsInvalid);
      expect(repoInvalid.getThemeMode(), ThemeMode.system);
    });

    test('Saves theme modes to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = SharedPreferencesThemeRepository(prefs);

      await repository.setThemeMode(ThemeMode.dark);
      expect(prefs.getString('app_theme_mode'), 'dark');

      await repository.setThemeMode(ThemeMode.light);
      expect(prefs.getString('app_theme_mode'), 'light');

      await repository.setThemeMode(ThemeMode.system);
      expect(prefs.getString('app_theme_mode'), 'system');
    });

    test(
      'InMemoryThemeRepository works independently without preferences',
      () async {
        final repo = InMemoryThemeRepository();
        expect(repo.getThemeMode(), ThemeMode.system);
        await repo.setThemeMode(ThemeMode.dark);
        expect(repo.getThemeMode(), ThemeMode.dark);
      },
    );
  });

  group('Theme persistence across app sessions', () {
    test(
      'themeModeProvider restores stored dark mode and writes updates',
      () async {
        SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
        final prefs = await SharedPreferences.getInstance();

        final container1 = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container1.dispose);

        expect(container1.read(themeModeProvider), ThemeMode.dark);

        container1.read(themeModeProvider.notifier).setMode(ThemeMode.light);
        expect(container1.read(themeModeProvider), ThemeMode.light);
        await Future<void>.delayed(Duration.zero);
        expect(prefs.getString('app_theme_mode'), 'light');

        // Simulate app restart with a fresh container using the same prefs
        final container2 = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container2.dispose);

        expect(container2.read(themeModeProvider), ThemeMode.light);
      },
    );
  });

  group('Profile and Auth public profile synchronization', () {
    test('FirebaseProfileRepository calls onSyncProfile and surfaces errors safely', () async {
      final sdk = _FakeSdkAuth()..createdUser = _FakeSdkUser();
      String? syncedUser;
      String? syncedName;
      String? syncedPhoto;
      var failSync = false;

      final repository = FirebaseProfileRepository(
        sdk,
        onSyncProfile: (userId, displayName, photoUrl) async {
          if (failSync) throw Exception('Firestore sync failed');
          syncedUser = userId;
          syncedName = displayName;
          syncedPhoto = photoUrl;
        },
      );

      await repository.updateIdentity(
        userId: 'sdk-user',
        displayName: ' Hà Nội Foodie ',
        photoUrl: 'https://example.com/avatar.jpg',
      );

      expect(syncedUser, 'sdk-user');
      expect(syncedName, 'Hà Nội Foodie');
      expect(syncedPhoto, 'https://example.com/avatar.jpg');

      failSync = true;
      await expectLater(
        repository.updateIdentity(
          userId: 'sdk-user',
          displayName: 'New Name',
          photoUrl: null,
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            contains('chưa đồng bộ được hồ sơ công khai'),
          ),
        ),
      );
    });

    test('FirebaseAuthRepository.signUp invokes onUserCreated and handles errors gracefully', () async {
      final sdk = _FakeSdkAuth();
      String? createdUid;
      String? createdName;
      var failSync = false;

      final repo = FirebaseAuthRepository(
        sdk,
        onUserCreated: (userId, displayName) async {
          if (failSync) throw Exception('Initial doc failed');
          createdUid = userId;
          createdName = displayName;
        },
      );

      await repo.signUp(
        email: 'user@example.com',
        password: 'password123',
        displayName: ' Minh ',
      );

      expect(createdUid, 'sdk-user');
      expect(createdName, 'Minh');

      failSync = true;
      // When onUserCreated throws, signUp does NOT fail because account is created
      await repo.signUp(
        email: 'user2@example.com',
        password: 'password123',
        displayName: ' Minh 2 ',
      );
      expect(sdk.createdUser?.displayName, 'Minh 2');
    });
  });
}
