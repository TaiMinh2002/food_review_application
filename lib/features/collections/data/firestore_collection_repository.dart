import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_search.dart';
import '../domain/collection_editor.dart';
import '../domain/collection_repository.dart';

typedef PlaceLookup = Future<Place?> Function(String placeId);

/// Real Firestore-backed collection repository for owner-scoped collections.
/// Stored under `users/{ownerId}/collections/{collectionId}` with inline `placeIds`.
class FirestoreCollectionRepository
    implements CollectionRepository, CollectionEditingRepository {
  FirestoreCollectionRepository(
    this._firestore, {
    PlaceLookup? placeLookup,
    this.getCollectionsHook,
    this.getCollectionHook,
    this.createCollectionHook,
    this.updateCollectionHook,
    this.deleteCollectionHook,
  }) : _placeLookup = placeLookup ?? _defaultLookup;

  final FirebaseFirestore? _firestore;
  final PlaceLookup _placeLookup;

  final Future<CollectionPage> Function(
    String ownerId,
    CollectionSort sort,
    String? cursor,
    int limit,
  )?
  getCollectionsHook;

  final Future<CollectionDetail?> Function(String ownerId, String collectionId)?
  getCollectionHook;

  final Future<String> Function(
    String ownerId,
    String requestId,
    CollectionDraft draft,
  )?
  createCollectionHook;

  final Future<void> Function(
    String ownerId,
    String collectionId,
    CollectionDraft draft,
  )?
  updateCollectionHook;

  final Future<void> Function(String ownerId, String collectionId)?
  deleteCollectionHook;

  static Future<Place?> _defaultLookup(String _) async => null;

  @override
  bool get isDemo => false;

  CollectionReference<Map<String, dynamic>> _collection(String ownerId) =>
      _firestore!.collection('users').doc(ownerId).collection('collections');

  @override
  Future<CollectionPage> getCollections({
    required String ownerId,
    CollectionSort sort = CollectionSort.recent,
    String? cursor,
    int limit = 12,
  }) async {
    final owner = ownerId.trim();
    if (owner.isEmpty) throw const AppException('Vui lòng đăng nhập.');
    if (limit < 1 || limit > 50) throw ArgumentError.value(limit, 'limit');

    if (getCollectionsHook != null) {
      return getCollectionsHook!(owner, sort, cursor, limit);
    }

    try {
      final snapshot = await _collection(owner).get();
      final records = snapshot.docs.map((doc) {
        final data = doc.data();
        final rawUpdatedAt = data['updatedAt'];
        DateTime updatedAt;
        if (rawUpdatedAt is Timestamp) {
          updatedAt = rawUpdatedAt.toDate();
        } else if (rawUpdatedAt is DateTime) {
          updatedAt = rawUpdatedAt;
        } else {
          updatedAt = DateTime.now();
        }
        final placeIds = (data['placeIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        return PlaceCollection(
          id: doc.id,
          ownerId: owner,
          name: data['name'] as String? ?? '',
          description: data['description'] as String? ?? '',
          placeCount: placeIds.length,
          updatedAt: updatedAt,
          coverUrl: data['coverUrl'] as String?,
        );
      }).toList();

      records.sort((a, b) {
        final order = switch (sort) {
          CollectionSort.recent => b.updatedAt.compareTo(a.updatedAt),
          CollectionSort.name => normalizePlaceSearchText(
            a.name,
          ).compareTo(normalizePlaceSearchText(b.name)),
          CollectionSort.mostPlaces => b.placeCount.compareTo(a.placeCount),
        };
        return order == 0 ? a.id.compareTo(b.id) : order;
      });

      var start = 0;
      if (cursor != null) {
        final parts = cursor.split(':');
        if (parts.length != 4 ||
            parts[0] != 'v1' ||
            parts[2] != sort.name ||
            int.tryParse(parts[3]) == null) {
          throw const AppException('Danh sách đã thay đổi. Vui lòng tải lại.');
        }
        start = int.parse(parts[3]);
        if (start < 0 || start > records.length) {
          throw const AppException(
            'Không tải được trang tiếp theo. Vui lòng tải lại.',
          );
        }
      }

      final end = (start + limit).clamp(0, records.length);
      return CollectionPage(
        items: records.sublist(start, end),
        total: records.length,
        nextCursor: end < records.length ? 'v1:0:${sort.name}:$end' : null,
        isDemo: false,
      );
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền xem bộ sưu tập này.'
            : 'Không thể tải danh sách bộ sưu tập lúc này.',
      );
    }
  }

  @override
  Future<void> deleteCollection({
    required String ownerId,
    required String collectionId,
  }) async {
    final owner = ownerId.trim();
    if (owner.isEmpty) throw const AppException('Vui lòng đăng nhập.');

    if (deleteCollectionHook != null) {
      return deleteCollectionHook!(owner, collectionId);
    }

    final docRef = _collection(owner).doc(collectionId);
    try {
      final existing = await docRef.get();
      if (!existing.exists) {
        throw const AppException(
          'Không tìm thấy bộ sưu tập trong tài khoản này.',
        );
      }
      await docRef.delete();
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền xóa bộ sưu tập này.'
            : 'Không thể xóa bộ sưu tập lúc này. Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<CollectionDetail?> getCollection({
    required String ownerId,
    required String collectionId,
  }) async {
    final owner = ownerId.trim();
    if (owner.isEmpty) return null;

    if (getCollectionHook != null) {
      return getCollectionHook!(owner, collectionId);
    }

    final docRef = _collection(owner).doc(collectionId);
    try {
      final doc = await docRef.get();
      if (!doc.exists) return null;
      final data = doc.data() ?? {};
      final name = data['name'] as String? ?? '';
      final description = data['description'] as String? ?? '';
      final placeIds = (data['placeIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();

      final places = await Future.wait(
        placeIds.map((id) async {
          final place = await _placeLookup(id);
          return CollectionPlace(
            id: id,
            name: place?.name ?? 'Địa điểm đã lưu',
            subtitle: place == null
                ? 'Bỏ địa điểm này trước khi lưu'
                : '${place.category} • ${place.address}',
            imageUrl: place?.imageUrls.firstOrNull,
            available: place != null,
          );
        }),
      );

      return CollectionDetail(
        id: collectionId,
        ownerId: owner,
        name: name,
        description: description,
        places: places,
        isDemo: false,
      );
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền truy cập bộ sưu tập này.'
            : 'Không tải được bộ sưu tập.',
      );
    }
  }

  @override
  Future<String> createCollection({
    required String ownerId,
    required String requestId,
    required CollectionDraft draft,
  }) async {
    final owner = ownerId.trim();
    if (owner.isEmpty) throw const AppException('Vui lòng đăng nhập.');
    if (requestId.trim().isEmpty) {
      throw const AppException(
        'Không tạo được bộ sưu tập. Vui lòng mở lại form.',
      );
    }
    final nameError = validateCollectionName(draft.name);
    if (nameError != null) throw AppException(nameError);
    final descError = validateCollectionDescription(draft.description);
    if (descError != null) throw AppException(descError);
    if (draft.placeIds.length > collectionPlaceLimit ||
        draft.placeIds.any((id) => id.trim().isEmpty)) {
      throw const AppException('Bộ sưu tập hỗ trợ tối đa 50 địa điểm hợp lệ.');
    }

    if (createCollectionHook != null) {
      return createCollectionHook!(owner, requestId, draft);
    }

    final docRef = _collection(owner).doc(requestId);
    try {
      final existing = await docRef.get();
      if (existing.exists) {
        final data = existing.data() ?? {};
        final existingName = data['name'] as String? ?? '';
        final existingDesc = data['description'] as String? ?? '';
        final existingPlaces = (data['placeIds'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        if (existingName == draft.name &&
            existingDesc == draft.description &&
            existingPlaces.length == draft.placeIds.length &&
            existingPlaces.asMap().entries.every(
              (e) => draft.placeIds[e.key] == e.value,
            )) {
          return requestId;
        }
        throw const AppException(
          'Bộ sưu tập đã được tạo với thông tin trước đó. Hãy quay lại danh sách để chỉnh sửa.',
        );
      }

      String? coverUrl;
      if (draft.placeIds.isNotEmpty) {
        final firstPlace = await _placeLookup(draft.placeIds.first);
        coverUrl = firstPlace?.imageUrls.firstOrNull;
      }

      await docRef.set({
        'name': draft.name,
        'description': draft.description,
        'placeIds': draft.placeIds,
        if (coverUrl != null && coverUrl.isNotEmpty) 'coverUrl': coverUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return requestId;
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền tạo bộ sưu tập này.'
            : 'Không thể lưu bộ sưu tập lúc này. Vui lòng thử lại sau.',
      );
    }
  }

  @override
  Future<void> updateCollection({
    required String ownerId,
    required String collectionId,
    required CollectionDraft draft,
  }) async {
    final owner = ownerId.trim();
    if (owner.isEmpty) throw const AppException('Vui lòng đăng nhập.');
    final nameError = validateCollectionName(draft.name);
    if (nameError != null) throw AppException(nameError);
    final descError = validateCollectionDescription(draft.description);
    if (descError != null) throw AppException(descError);
    if (draft.placeIds.length > collectionPlaceLimit ||
        draft.placeIds.any((id) => id.trim().isEmpty)) {
      throw const AppException('Bộ sưu tập hỗ trợ tối đa 50 địa điểm hợp lệ.');
    }

    if (updateCollectionHook != null) {
      return updateCollectionHook!(owner, collectionId, draft);
    }

    final docRef = _collection(owner).doc(collectionId);
    try {
      final existing = await docRef.get();
      if (!existing.exists) {
        throw const AppException('Không tìm thấy bộ sưu tập của bạn.');
      }

      String? coverUrl;
      if (draft.placeIds.isNotEmpty) {
        final firstPlace = await _placeLookup(draft.placeIds.first);
        coverUrl = firstPlace?.imageUrls.firstOrNull;
      }

      final updateData = <String, dynamic>{
        'name': draft.name,
        'description': draft.description,
        'placeIds': draft.placeIds,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (coverUrl != null && coverUrl.isNotEmpty) {
        updateData['coverUrl'] = coverUrl;
      } else {
        updateData['coverUrl'] = FieldValue.delete();
      }

      await docRef.update(updateData);
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền sửa bộ sưu tập này.'
            : 'Không thể cập nhật bộ sưu tập lúc này. Vui lòng thử lại.',
      );
    }
  }
}
