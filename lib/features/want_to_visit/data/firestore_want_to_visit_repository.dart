import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/want_to_visit_repository.dart';

class FirestoreWantToVisitRepository implements WantToVisitRepository {
  FirestoreWantToVisitRepository(
    this._firestore, {
    this.watchIds,
    this.saveWantToVisit,
  });

  final FirebaseFirestore? _firestore;
  final Stream<Set<String>> Function(String userId)? watchIds;
  final Future<void> Function(String userId, String placeId, bool value)?
  saveWantToVisit;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore!.collection('users').doc(userId).collection('wantToVisit');

  @override
  Stream<Set<String>> watchPlaceIds(String userId) {
    if (userId.trim().isEmpty) return Stream.value(const {});
    if (watchIds != null) return watchIds!(userId);
    return _collection(userId)
        .snapshots()
        .map((snapshot) {
          return Set<String>.unmodifiable(snapshot.docs.map((doc) => doc.id));
        })
        .handleError((error, stack) {
          throw const AppException('Không tải được danh sách muốn ghé.');
        });
  }

  @override
  Future<void> setWantToVisit({
    required String userId,
    required String placeId,
    required bool value,
  }) async {
    if (userId.trim().isEmpty) {
      throw const AppException('Vui lòng đăng nhập trước khi lưu quán.');
    }
    if (placeId.trim().isEmpty) {
      throw const AppException('Địa điểm không hợp lệ.');
    }
    if (saveWantToVisit != null) {
      return saveWantToVisit!(userId, placeId, value);
    }
    final docRef = _collection(userId).doc(placeId);
    try {
      if (value) {
        await docRef.set({
          'placeId': placeId,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await docRef.delete();
      }
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền thao tác với danh sách này.'
            : 'Không thể cập nhật danh sách muốn ghé. Vui lòng thử lại.',
        code: e.code,
      );
    } catch (_) {
      throw const AppException(
        'Không thể cập nhật danh sách muốn ghé. Vui lòng thử lại.',
      );
    }
  }
}
