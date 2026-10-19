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

final signOutControllerProvider =
    NotifierProvider.autoDispose<SignOutController, AsyncValue<void>>(
      SignOutController.new,
    );

class SignOutController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);
  Future<void> submit() async {
    if (state.isLoading) return;
    final repository = ref.read(authRepositoryProvider);
    final reference = ref;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(repository.signOut);
    if (reference.mounted) state = result;
  }
}
