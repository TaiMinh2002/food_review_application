import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  FirebaseProfileRepository(this.auth, {this.firestore, this.onSyncProfile});
  final FirebaseAuth auth;
  final FirebaseFirestore? firestore;
  final Future<void> Function(
    String userId,
    String displayName,
    String? photoUrl,
  )?
  onSyncProfile;

  @override
  Future<void> updateIdentity({
    required String userId,
    required String displayName,
    required String? photoUrl,
  }) async {
    final user = auth.currentUser;
    if (user == null || user.uid != userId) {
      throw const AppException(
        'Phiên đăng nhập đã thay đổi. Vui lòng thử lại.',
      );
    }
    final error = validateProfileName(displayName);
    if (error != null) throw AppException(error);
    final cleanName = displayName.trim();
    try {
      // One Auth operation prevents partial name/photo updates.
      await user.updateProfile(displayName: cleanName, photoURL: photoUrl);
    } on FirebaseAuthException catch (error) {
      throw AppException(
        error.code == 'network-request-failed'
            ? 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.'
            : 'Không lưu được hồ sơ. Vui lòng thử lại.',
      );
    }

    if (onSyncProfile != null) {
      try {
        await onSyncProfile!(userId, cleanName, photoUrl);
      } catch (_) {
        throw const AppException(
          'Đã cập nhật tài khoản nhưng chưa đồng bộ được hồ sơ công khai. Vui lòng thử lại.',
        );
      }
    } else if (firestore != null) {
      try {
        await firestore!.collection('users').doc(userId).set({
          'displayName': cleanName,
          'photoUrl': ?photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {
        throw const AppException(
          'Đã cập nhật tài khoản nhưng chưa đồng bộ được hồ sơ công khai. Vui lòng thử lại.',
        );
      }
    }
  }
}

class UnavailableProfileRepository implements ProfileRepository {
  @override
  Future<void> updateIdentity({
    required String userId,
    required String displayName,
    required String? photoUrl,
  }) async => throw const AppException('Dịch vụ hồ sơ chưa được khởi tạo.');
}
