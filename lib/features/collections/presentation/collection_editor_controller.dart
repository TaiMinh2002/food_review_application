import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/collection_editor.dart';
import 'collections_controller.dart';

typedef CollectionEditorKey = ({
  String ownerId,
  String? collectionId,
  String scope,
});

final collectionDetailProvider = FutureProvider.autoDispose
    .family<CollectionDetail?, CollectionEditorKey>((ref, key) async {
      final session = ref.watch(authSessionProvider);
      if (session.isLoading ||
          session.hasError ||
          session.asData?.value?.id != key.ownerId) {
        throw const AppException('Phiên đăng nhập đã thay đổi.');
      }
      if (key.collectionId == null) return null;
      final repository = ref.watch(collectionRepositoryProvider);
      if (repository is! CollectionEditingRepository) {
        throw const AppException(
          'Nguồn dữ liệu chưa hỗ trợ chỉnh sửa bộ sưu tập.',
        );
      }
      final detail = await (repository as CollectionEditingRepository)
          .getCollection(ownerId: key.ownerId, collectionId: key.collectionId!);
      if (detail != null &&
          (detail.ownerId != key.ownerId ||
              detail.id != key.collectionId ||
              detail.places.length > collectionPlaceLimit ||
              detail.places.map((p) => p.id).toSet().length !=
                  detail.places.length)) {
        throw const AppException('Không đọc được bộ sưu tập của bạn.');
      }
      return detail;
    }, retry: (_, _) => null);

final collectionSaveProvider = NotifierProvider.autoDispose
    .family<CollectionSaveController, AsyncValue<void>, CollectionEditorKey>(
      CollectionSaveController.new,
    );

class CollectionSaveController extends Notifier<AsyncValue<void>> {
  CollectionSaveController(this.key);
  final CollectionEditorKey key;
  late final _requestId =
      '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';
  @override
  AsyncValue<void> build() {
    ref.watch(
      authSessionProvider.select((session) => session.asData?.value?.id),
    );
    return const AsyncData(null);
  }

  bool get _sameOwner {
    final session = ref.read(authSessionProvider);
    return !session.isLoading &&
        !session.hasError &&
        session.asData?.value?.id == key.ownerId;
  }

  Future<String?> save(CollectionDraft draft) async {
    if (state.isLoading || !_sameOwner) return null;
    final reference = ref;
    final repository = ref.read(collectionRepositoryProvider);
    state = const AsyncLoading();
    try {
      final error =
          validateCollectionName(draft.name) ??
          validateCollectionDescription(draft.description);
      if (error != null) throw AppException(error);
      if (repository is! CollectionEditingRepository) {
        throw const AppException('Nguồn dữ liệu chưa hỗ trợ lưu bộ sưu tập.');
      }
      final editor = repository as CollectionEditingRepository;
      final String id;
      if (key.collectionId == null) {
        id = await editor.createCollection(
          ownerId: key.ownerId,
          requestId: _requestId,
          draft: draft,
        );
      } else {
        await editor.updateCollection(
          ownerId: key.ownerId,
          collectionId: key.collectionId!,
          draft: draft,
        );
        id = key.collectionId!;
      }
      if (!reference.mounted || !_sameOwner) return null;
      if (id.isEmpty) {
        throw const AppException(
          'Không lưu được bộ sưu tập. Vui lòng thử lại.',
        );
      }
      // Keep T21's selected sort and refresh the first page after mutation.
      await ref.read(collectionsControllerProvider.notifier).refresh();
      if (!reference.mounted || !_sameOwner) return null;
      state = const AsyncData(null);
      return id;
    } catch (error, stack) {
      if (reference.mounted && _sameOwner) state = AsyncError(error, stack);
      return null;
    }
  }
}
