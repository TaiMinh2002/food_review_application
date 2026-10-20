import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../places/domain/place_search.dart';
import '../../places/presentation/search_controller.dart';
import '../domain/collection_editor.dart';

Future<List<CollectionPlace>?> pickCollectionPlaces(
  BuildContext context, {
  required String ownerId,
  required List<CollectionPlace> selected,
}) => showModalBottomSheet<List<CollectionPlace>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: .9,
    child: _CollectionPicker(ownerId: ownerId, selected: selected),
  ),
);

class _CollectionPicker extends ConsumerStatefulWidget {
  const _CollectionPicker({required this.ownerId, required this.selected});
  final String ownerId;
  final List<CollectionPlace> selected;
  @override
  ConsumerState<_CollectionPicker> createState() => _CollectionPickerState();
}

class _CollectionPickerState extends ConsumerState<_CollectionPicker> {
  late final _selected = {for (final place in widget.selected) place.id: place};
  final _query = TextEditingController();
  late final SearchSeed _seed = (
    request: PlaceSearchRequest(),
    scope: 'collection-picker-${identityHashCode(this)}',
  );
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authSessionProvider, (_, next) {
      if (next.isLoading ||
          next.hasError ||
          next.asData?.value?.id != widget.ownerId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    });
    final session = ref.watch(authSessionProvider);
    if (session.isLoading ||
        session.hasError ||
        session.asData?.value?.id != widget.ownerId) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(searchControllerProvider(_seed));
    final controller = ref.read(searchControllerProvider(_seed).notifier);
    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Thêm vào bộ sưu tập',
              style: context.textStyles.titleLarge,
            ),
          ),
          IconButton(
            tooltip: 'Đóng danh sách địa điểm',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
    final footer = Padding(
      padding: AppSpacing.page,
      child: AppButton(
        label: 'Áp dụng (${_selected.length} địa điểm)',
        expanded: true,
        onPressed: () {
          final session = ref.read(authSessionProvider);
          if (!session.isLoading &&
              !session.hasError &&
              session.asData?.value?.id == widget.ownerId) {
            Navigator.pop(context, _selected.values.toList());
          }
        },
      ),
    );
    final slivers = <Widget>[
      SliverPadding(
        padding: AppSpacing.page,
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                controller: _query,
                hintText: 'Tìm tên quán, món ăn…',
                onChanged: controller.setQuery,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Đã chọn ${_selected.length}/$collectionPlaceLimit địa điểm',
                style: context.textStyles.labelMedium,
              ),
              if (state.isDemo)
                Text(
                  'Danh sách quán minh họa',
                  style: context.textStyles.labelSmall,
                ),
            ],
          ),
        ),
      ),
      if (state.isLoading)
        const SliverPadding(
          padding: AppSpacing.page,
          sliver: SliverToBoxAdapter(child: AppSkeleton(height: 120)),
        )
      else if (state.error != null)
        SliverToBoxAdapter(
          child: AppErrorState(
            message: state.error!,
            onRetry: controller.retry,
          ),
        )
      else if (state.items.isEmpty)
        const SliverToBoxAdapter(
          child: AppEmptyState(
            title: 'Không tìm thấy địa điểm',
            message: 'Thử tìm bằng tên quán hoặc món ăn khác.',
            icon: Icons.search_off,
          ),
        )
      else
        SliverList.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final place = state.items[index];
            return CheckboxListTile(
              key: ValueKey('pick-${place.id}'),
              value: _selected.containsKey(place.id),
              secondary: ClipRRect(
                borderRadius: AppRadii.inputBorder,
                child: AppImage(
                  url: place.imageUrls.firstOrNull,
                  width: 48,
                  height: 48,
                ),
              ),
              title: Text(place.name),
              subtitle: Text('${place.category} • ${place.address}'),
              onChanged: (checked) {
                if (checked == true &&
                    _selected.length >= collectionPlaceLimit) {
                  AppToast.show(
                    context,
                    'Bộ sưu tập hỗ trợ tối đa $collectionPlaceLimit địa điểm.',
                  );
                  return;
                }
                setState(() {
                  if (checked == true) {
                    _selected[place.id] = CollectionPlace(
                      id: place.id,
                      name: place.name,
                      subtitle: '${place.category} • ${place.address}',
                      imageUrl: place.imageUrls.firstOrNull,
                    );
                  } else {
                    _selected.remove(place.id);
                  }
                });
              },
            );
          },
        ),
      SliverToBoxAdapter(
        child: Column(
          children: [
            if (state.pageError != null)
              Text(
                state.pageError!,
                style: TextStyle(color: context.colors.error),
              ),
            if (state.nextCursor != null)
              TextButton(
                onPressed: state.isLoadingMore ? null : controller.loadMore,
                child: Text(
                  state.isLoadingMore ? 'Đang tải…' : 'Tải thêm địa điểm',
                ),
              ),
          ],
        ),
      ),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep the whole sheet scrollable when a keyboard leaves little height.
            if (constraints.maxHeight < 340) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: header),
                  ...slivers,
                  SliverToBoxAdapter(child: footer),
                ],
              );
            }
            return Column(
              children: [
                header,
                Expanded(child: CustomScrollView(slivers: slivers)),
                footer,
              ],
            );
          },
        ),
      ),
    );
  }
}
