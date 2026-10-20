import '../../../core/errors/app_exception.dart';
import '../domain/collection_repository.dart';
import '../domain/collection_editor.dart';
import '../../places/domain/place_repository.dart';
import '../../places/data/demo_place_repository.dart';
import '../../places/domain/place_search.dart';

/// Owner-scoped illustrative collections, stored only for this app process.
/// No favorite/want-to-visit repository is read or changed here.
class DemoCollectionRepository
    implements CollectionRepository, CollectionEditingRepository {
  DemoCollectionRepository({this.seedExamples = true, PlaceRepository? places})
    : _places = places ?? DemoPlaceRepository();
  final PlaceRepository _places;
  final bool seedExamples;
  @override
  bool get isDemo => true;
  final _records = <String, Map<String, _Record>>{};
  final _revisions = <String, int>{};

  Map<String, _Record> _forOwner(String owner) {
    if (owner.trim().isEmpty) throw const AppException('Vui lòng đăng nhập.');
    return _records.putIfAbsent(owner, () => seedExamples ? _examples() : {});
  }

  @override
  Future<CollectionPage> getCollections({
    required String ownerId,
    CollectionSort sort = CollectionSort.recent,
    String? cursor,
    int limit = 12,
  }) async {
    if (limit < 1 || limit > 50) throw ArgumentError.value(limit, 'limit');
    final records = _forOwner(ownerId).entries.toList();
    records.sort((a, b) {
      final order = switch (sort) {
        CollectionSort.recent => b.value.updatedAt.compareTo(a.value.updatedAt),
        CollectionSort.name => normalizePlaceSearchText(
          a.value.name,
        ).compareTo(normalizePlaceSearchText(b.value.name)),
        CollectionSort.mostPlaces => b.value.placeIds.length.compareTo(
          a.value.placeIds.length,
        ),
      };
      return order == 0 ? a.key.compareTo(b.key) : order;
    });
    final revision = _revisions[ownerId] ?? 0;
    var start = 0;
    if (cursor != null) {
      final parts = cursor.split(':');
      if (parts.length != 4 ||
          parts[0] != 'v1' ||
          int.tryParse(parts[1]) != revision ||
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
      items: records
          .sublist(start, end)
          .map(
            (entry) => PlaceCollection(
              id: entry.key,
              ownerId: ownerId,
              name: entry.value.name,
              description: entry.value.description,
              placeCount: entry.value.placeIds.length,
              updatedAt: entry.value.updatedAt,
              coverUrl: entry.value.coverUrl,
            ),
          )
          .toList(),
      total: records.length,
      nextCursor: end < records.length
          ? 'v1:$revision:${sort.name}:$end'
          : null,
      isDemo: true,
    );
  }

  @override
  Future<void> deleteCollection({
    required String ownerId,
    required String collectionId,
  }) async {
    final records = _forOwner(ownerId);
    if (!records.containsKey(collectionId)) {
      throw const AppException(
        'Không tìm thấy bộ sưu tập trong tài khoản này.',
      );
    }
    records.remove(collectionId);
    _revisions.update(ownerId, (value) => value + 1, ifAbsent: () => 1);
  }

  @override
  Future<CollectionDetail?> getCollection({
    required String ownerId,
    required String collectionId,
  }) async {
    final record = _forOwner(ownerId)[collectionId];
    if (record == null) return null;
    final places = await Future.wait(
      record.placeIds.map((id) async {
        final place = await _places.getPlace(id);
        return CollectionPlace(
          id: id,
          name: place?.name ?? 'Địa điểm không còn khả dụng',
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
      ownerId: ownerId,
      name: record.name,
      description: record.description,
      places: places,
      isDemo: true,
    );
  }

  Future<_Record> _prepare(CollectionDraft draft) async {
    final error =
        validateCollectionName(draft.name) ??
        validateCollectionDescription(draft.description);
    if (error != null) throw AppException(error);
    if (draft.placeIds.length > collectionPlaceLimit ||
        draft.placeIds.any((id) => id.trim().isEmpty)) {
      throw const AppException('Bộ sưu tập hỗ trợ tối đa 50 địa điểm hợp lệ.');
    }
    final places = await Future.wait(draft.placeIds.map(_places.getPlace));
    if (places.any((place) => place == null)) {
      throw const AppException(
        'Một địa điểm không còn khả dụng. Vui lòng bỏ địa điểm đó và thử lại.',
      );
    }
    return _Record(
      draft.name,
      draft.description,
      draft.placeIds,
      places.firstOrNull?.imageUrls.firstOrNull,
      DateTime.now(),
    );
  }

  @override
  Future<String> createCollection({
    required String ownerId,
    required String requestId,
    required CollectionDraft draft,
  }) async {
    final records = _forOwner(ownerId);
    if (requestId.isEmpty) {
      throw const AppException(
        'Không tạo được bộ sưu tập. Vui lòng mở lại form.',
      );
    }
    final id = 'created-$requestId';
    if (records.containsKey(id)) {
      _checkRetry(records[id]!, draft);
      return id;
    }
    final record = await _prepare(draft);
    // Recheck after async lookups to keep create idempotent under concurrency.
    if (records.containsKey(id)) {
      _checkRetry(records[id]!, draft);
    } else {
      records[id] = record;
      _revisions.update(ownerId, (value) => value + 1, ifAbsent: () => 1);
    }
    return id;
  }

  void _checkRetry(_Record record, CollectionDraft draft) {
    if (record.name != draft.name ||
        record.description != draft.description ||
        record.placeIds.length != draft.placeIds.length ||
        record.placeIds.asMap().entries.any(
          (entry) => draft.placeIds[entry.key] != entry.value,
        )) {
      throw const AppException(
        'Bộ sưu tập đã được tạo với thông tin trước đó. Hãy quay lại danh sách để chỉnh sửa.',
      );
    }
  }

  @override
  Future<void> updateCollection({
    required String ownerId,
    required String collectionId,
    required CollectionDraft draft,
  }) async {
    final records = _forOwner(ownerId);
    if (!records.containsKey(collectionId)) {
      throw const AppException('Không tìm thấy bộ sưu tập của bạn.');
    }
    final record = await _prepare(draft);
    if (!records.containsKey(collectionId)) {
      throw const AppException(
        'Bộ sưu tập đã bị xóa. Vui lòng tải lại danh sách.',
      );
    }
    records[collectionId] = record;
    _revisions.update(ownerId, (value) => value + 1, ifAbsent: () => 1);
  }

  Map<String, _Record> _examples() => {
    'hanoi-demo': _Record(
      'Quán ngon Hà Nội',
      'Ẩm thực địa phương',
      {'pho-demo', 'banh-mi-demo'},
      'assets/images/demo/collection_hanoi.jpg',
      DateTime(2026, 10, 20),
    ),
    'date-demo': _Record(
      'Đi hẹn hò',
      'Không gian lãng mạn',
      {'coffee-demo', 'pho-demo'},
      'assets/images/demo/collection_date.jpg',
      DateTime(2026, 10, 19),
    ),
    'coffee-demo': _Record(
      'Cà phê đẹp',
      'Không gian thư giãn',
      {'coffee-demo'},
      'assets/images/demo/collection_coffee.jpg',
      DateTime(2026, 10, 18),
    ),
    'budget-demo': _Record(
      'Ăn ngon tiết kiệm',
      'Phù hợp túi tiền',
      {'banh-mi-demo'},
      'assets/images/demo/collection_budget.jpg',
      DateTime(2026, 10, 17),
    ),
  };
}

class _Record {
  _Record(
    this.name,
    this.description,
    Iterable<String> placeIds,
    this.coverUrl,
    this.updatedAt,
  ) : placeIds = List.unmodifiable(placeIds.toSet());
  final String name, description;
  final String? coverUrl;
  final List<String> placeIds;
  final DateTime updatedAt;
}
