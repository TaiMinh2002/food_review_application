import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design_system/design_system.dart';
import '../../places/domain/place_search.dart';
import '../../places/presentation/search_controller.dart';

Future<String?> pickReviewPlace(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          const FractionallySizedBox(heightFactor: .85, child: _PlacePicker()),
    );

class _PlacePicker extends ConsumerStatefulWidget {
  const _PlacePicker();
  @override
  ConsumerState<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends ConsumerState<_PlacePicker> {
  late final SearchSeed _seed = (
    request: PlaceSearchRequest(),
    scope: 'review-picker-${identityHashCode(this)}',
  );
  final _query = TextEditingController();
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider(_seed));
    final controller = ref.read(searchControllerProvider(_seed).notifier);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.margin,
        0,
        AppSpacing.margin,
        MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Chọn quán để viết đánh giá',
                  style: context.textStyles.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                AppSearchField(
                  controller: _query,
                  hintText: 'Tìm tên quán, món ăn…',
                  onChanged: controller.setQuery,
                ),
                const SizedBox(height: AppSpacing.md),
                if (state.isDemo) const Text('Danh sách quán minh họa'),
              ],
            ),
          ),
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
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
                title: 'Không tìm thấy quán',
                message: 'Thử tên quán hoặc món ăn khác.',
                icon: Icons.search_off,
              ),
            )
          else
            SliverList.builder(
              itemCount: state.items.length + 1,
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return Column(
                    children: [
                      if (state.pageError != null) Text(state.pageError!),
                      if (state.nextCursor != null)
                        TextButton(
                          onPressed: state.isLoadingMore
                              ? null
                              : controller.loadMore,
                          child: Text(
                            state.isLoadingMore ? 'Đang tải…' : 'Tải thêm quán',
                          ),
                        ),
                    ],
                  );
                }
                final place = state.items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: AppRadii.inputBorder,
                    child: AppImage(
                      url: place.imageUrls.firstOrNull,
                      width: 48,
                      height: 48,
                    ),
                  ),
                  title: Text(place.name),
                  subtitle: Text(place.address),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, place.id),
                );
              },
            ),
        ],
      ),
    );
  }
}
