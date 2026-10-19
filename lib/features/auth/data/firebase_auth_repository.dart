import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/auth_repository.dart';

AppException authFailure(String code) => AppException(switch (code) {
  'invalid-credential' ||
  'invalid-login-credentials' ||
  'wrong-password' ||
  'user-not-found' => 'Email hoặc mật khẩu không chính xác.',
  'invalid-email' => 'Vui lòng nhập địa chỉ email hợp lệ.',
  'email-already-in-use' =>
    'Email này đã được đăng ký. Hãy đăng nhập hoặc sử dụng email khác.',
  'weak-password' => 'Mật khẩu chưa đủ mạnh. Hãy dùng ít nhất 8 ký tự.',
  'network-request-failed' =>
    'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.',
  'too-many-requests' => 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.',
  'user-disabled' =>
    'Tài khoản hiện không thể đăng nhập. Vui lòng liên hệ hỗ trợ.',
  'operation-not-allowed' ||
  'configuration-not-found' ||
  'invalid-api-key' ||
  'app-not-authorized' =>
    'Dịch vụ đăng nhập chưa sẵn sàng. Vui lòng thử lại sau.',
  _ => 'Không thể hoàn tất xác thực. Vui lòng thử lại.',
}, code: code);

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth);
  final FirebaseAuth auth;
  @override
  Stream<UserProfile?> authStateChanges() => auth
      .authStateChanges()
      .map(
        (user) => user == null
            ? null
            : UserProfile(
                id: user.uid,
                displayName: user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!.trim()
                    : 'Thành viên',
                photoUrl: user.photoURL,
              ),
      )
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stack, sink) {
            sink.addError(
              error is FirebaseAuthException
                  ? authFailure(error.code)
                  : const AppException('Không kiểm tra được phiên đăng nhập.'),
              stack,
            );
          },
        ),
      );
  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw authFailure(error.code);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } on FirebaseAuthException catch (error) {
      throw authFailure(error.code);
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException(
          'Không tạo được tài khoản. Vui lòng thử lại.',
          code: 'account-not-created',
        );
      }
      try {
        await user.updateDisplayName(displayName.trim());
      } on FirebaseAuthException catch (error) {
        throw AppException(
          'Tài khoản đã được tạo nhưng chưa lưu được tên hiển thị. '
          'Bạn có thể đăng nhập và cập nhật lại.',
          code: error.code,
        );
      }
    } on FirebaseAuthException catch (error) {
      throw authFailure(error.code);
    }
  }
}

/// Never invents a successful authentication when Firebase is unavailable.
class UnavailableAuthRepository implements AuthRepository {
  @override
  Stream<UserProfile?> authStateChanges() => Stream.value(null);
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async => throw const AppException(
    'Dịch vụ đăng nhập chưa được khởi tạo. Vui lòng mở lại ứng dụng.',
  );
  @override
  Future<void> signOut() async =>
      throw const AppException('Không kiểm tra được phiên đăng nhập.');
  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async => throw const AppException(
    'Dịch vụ đăng ký chưa được khởi tạo. Vui lòng thử lại sau.',
  );
}
