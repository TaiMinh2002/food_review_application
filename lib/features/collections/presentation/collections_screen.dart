import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/collection_repository.dart';
import 'collection_card.dart';
import 'collections_controller.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  static String sortLabel(CollectionSort sort) => switch (sort) {
    CollectionSort.recent => 'Gần đây nhất',
    CollectionSort.name => 'Tên A–Z',
    CollectionSort.mostPlaces => 'Nhiều địa điểm nhất',
  };

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PlaceCollection item,
  ) async {
    final confirmed = await showAppConfirmation(
      context,
      title: 'Xóa bộ sưu tập?',
      message:
          'Xóa “${item.name}”? Các quán trong Yêu thích và Muốn ghé thăm không bị xóa.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!context.mounted || !confirmed) return;
    final session = ref.read(authSessionProvider);
    if (session.isLoading ||
        session.hasError ||
        session.asData?.value?.id != item.ownerId) {
      return;
    }
    final success = await ref
        .read(collectionDeletionProvider.notifier)
        .remove(ownerId: item.ownerId, collectionId: item.id);
    if (!context.mounted) return;
    final current = ref.read(authSessionProvider);
    if (current.isLoading ||
        current.hasError ||
        current.asData?.value?.id != item.ownerId) {
      return;
    }
    if (success) {
      AppToast.show(
        context,
        'Đã xóa bộ sưu tập',
        type: AppFeedbackType.success,
      );
    } else {
      final error = ref.read(collectionDeletionProvider).error;
      if (error != null) {
        AppToast.show(
          context,
          AppErrorMessage.from(
            error,
            fallback: 'Không xóa được bộ sưu tập. Vui lòng thử lại.',
          ),
          type: AppFeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final canCreate =
        !session.isLoading &&
        !session.hasError &&
        session.asData?.value != null;
    void create() => context.push(AppRoute.createCollection.path);
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoute.profile.path);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bộ sưu tập'),
          centerTitle: true,
          leading: IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoute.profile.path),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: IconButton.filled(
                tooltip: 'Tạo bộ sưu tập mới',
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                ),
                onPressed: canCreate ? create : null,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: AuthGate(
            returnTo: AppRoute.collections.path,
            child: _CollectionsBody(
              onCreate: create,
              onDelete: (item) => _delete(context, ref, item),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionsBody extends ConsumerWidget {
  const _CollectionsBody({required this.onCreate, required this.onDelete});
  final VoidCallback onCreate;
  final ValueChanged<PlaceCollection> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collectionsControllerProvider);
    final controller = ref.read(collectionsControllerProvider.notifier);
    final deleting = ref.watch(collectionDeletionProvider).isLoading;
    void edit(PlaceCollection item) => context.push(
      AppRoute.editCollection.location(parameters: {'collectionId': item.id}),
    );
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        key: const PageStorageKey('collections-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.lg,
              AppSpacing.margin,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: AppRadii.inputBorder,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: context.colors.secondary,
                                    size: 8,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Những địa điểm của riêng bạn',
                                      style: context.textStyles.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Gom các quán yêu thích thành bộ sưu tập để dễ dàng tìm lại cho mọi dịp thưởng thức.',
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: context.colors.primaryContainer,
                          child: Icon(
                            Icons.bookmarks_outlined,
                            color: context.colors.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.isDemo)
                    Text(
                      'Bộ sưu tập mẫu • Chỉ lưu trong phiên ứng dụng',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tính năng tạo/chỉnh sửa sẽ được bổ sung.',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Bộ sưu tập của bạn',
                        style: context.textStyles.titleMedium,
                      ),
                      if (!state.loading && state.error == null)
                        AppBadge(
                          label: '${state.total} bộ sưu tập',
                          tone: AppBadgeTone.primary,
                        ),
                      PopupMenuButton<CollectionSort>(
                        tooltip: 'Sắp xếp bộ sưu tập',
                        initialValue: state.sort,
                        enabled: !deleting && !state.loading,
                        onSelected: controller.applySort,
                        itemBuilder: (_) => CollectionSort.values
                            .map(
                              (sort) => CheckedPopupMenuItem(
                                value: sort,
                                checked: sort == state.sort,
                                child: Text(CollectionsScreen.sortLabel(sort)),
                              ),
                            )
                            .toList(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_vert,
                                size: 18,
                                color: context.colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                CollectionsScreen.sortLabel(state.sort),
                                style: context.textStyles.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (deleting || state.refreshing)
                    LinearProgressIndicator(
                      value: MediaQuery.disableAnimationsOf(context) ? 0 : null,
                      semanticsLabel: deleting
                          ? 'Đang xóa bộ sưu tập'
                          : 'Đang tải lại',
                    ),
                  if (state.error != null)
                    AppErrorState(
                      message: state.error!,
                      onRetry: controller.refresh,
                    ),
                ],
              ),
            ),
          ),
          if (state.loading)
            const SliverPadding(
              padding: AppSpacing.page,
              sliver: SliverToBoxAdapter(child: AppSkeleton(height: 240)),
            )
          else if (state.items.isEmpty && state.error == null)
            SliverToBoxAdapter(
              child: AppEmptyState(
                icon: Icons.collections_bookmark_outlined,
                title: 'Bạn chưa có bộ sưu tập nào',
                message: 'Tạo bộ sưu tập đầu tiên để sắp xếp những quán ăn bạn muốn khám phá và lưu giữ kỷ niệm vị giác.',
                actionLabel: 'Tạo bộ sưu tập',
                onAction: onCreate,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.crossAxisExtent < 320 ||
                          MediaQuery.textScalerOf(context).scale(14) > 18
                      ? 1
                      : 2;
                  return SliverList.builder(
                    itemCount: (state.items.length / columns).ceil(),
                    itemBuilder: (context, row) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var col = 0; col < columns; col++) ...[
                            if (col > 0) const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: row * columns + col >= state.items.length
                                  ? const SizedBox.shrink()
                                  : CollectionCard(
                                      collection:
                                          state.items[row * columns + col],
                                      busy: deleting,
                                      onOpen: () => edit(
                                        state.items[row * columns + col],
                                      ),
                                      onAction: (action) =>
                                          action == CollectionAction.edit
                                          ? edit(
                                              state.items[row * columns + col],
                                            )
                                          : onDelete(
                                              state.items[row * columns + col],
                                            ),
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          SliverPadding(
            padding: AppSpacing.page,
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  if (state.pageError != null)
                    Text(
                      state.pageError!,
                      style: TextStyle(color: context.colors.error),
                    ),
                  if (state.nextCursor != null)
                    AppButton(
                      label: 'Tải thêm bộ sưu tập',
                      isLoading: state.loadingMore,
                      variant: AppButtonVariant.outline,
                      onPressed:
                          deleting || state.loadingMore || state.refreshing
                          ? null
                          : controller.loadMore,
                    ),
                  if (state.pageError != null)
                    TextButton(
                      onPressed: controller.refresh,
                      child: const Text('Tải lại danh sách'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
