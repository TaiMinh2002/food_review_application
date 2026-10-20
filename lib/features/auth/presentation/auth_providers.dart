import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/user_profile.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => Firebase.apps.isEmpty
      ? UnavailableAuthRepository()
      : FirebaseAuthRepository(FirebaseAuth.instance),
);
final authSessionProvider = StreamProvider<UserProfile?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
  retry: (_, _) => null,
);

final signInControllerProvider = NotifierProvider.autoDispose
    .family<SignInController, AsyncValue<void>, String>(SignInController.new);

class SignInController extends Notifier<AsyncValue<void>> {
  SignInController(this.scope);
  final String scope;
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<void> submit(String email, String password) async {
    if (state.isLoading) return;
    final repository = ref.read(authRepositoryProvider);
    final reference = ref;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => repository.signIn(email: email.trim(), password: password),
    );
    if (reference.mounted) state = result;
  }
}

final registerControllerProvider = NotifierProvider.autoDispose
    .family<RegisterController, AsyncValue<void>, String>(
      RegisterController.new,
    );

class RegisterController extends Notifier<AsyncValue<void>> {
  RegisterController(this.scope);
  final String scope;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (state.isLoading) return;
    final repository = ref.read(authRepositoryProvider);
    final reference = ref;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => repository.signUp(
        displayName: displayName.trim(),
        email: email.trim(),
        password: password,
      ),
    );
    if (reference.mounted) state = result;
  }
}

final forgotPasswordControllerProvider = NotifierProvider.autoDispose
    .family<ForgotPasswordController, AsyncValue<void>, String>(
      ForgotPasswordController.new,
    );

class ForgotPasswordController extends Notifier<AsyncValue<void>> {
  ForgotPasswordController(this.scope);
  final String scope;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit(String email) async {
    if (state.isLoading) return;
    final repository = ref.read(authRepositoryProvider);
    final reference = ref;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => repository.resetPassword(email: email.trim()),
    );
    if (reference.mounted) state = result;
  }
}

final signOutControllerProvider =
    NotifierProvider.autoDispose<SignOutController, AsyncValue<void>>(
      SignOutController.new,
    );

class SignOutController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    ref.watch(
      authSessionProvider.select((session) => session.asData?.value?.id),
    );
    return const AsyncData(null);
  }

  Future<bool> submit() async {
    if (state.isLoading) return false;
    final repository = ref.read(authRepositoryProvider);
    final reference = ref;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(repository.signOut);
    if (reference.mounted) state = result;
    return !result.hasError;
  }
}
