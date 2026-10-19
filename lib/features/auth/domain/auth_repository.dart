import '../../profile/domain/user_profile.dart';

abstract interface class AuthRepository {
  Stream<UserProfile?> authStateChanges();
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> resetPassword({required String email});
  Future<void> signOut();
}
