import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';
import 'place_card.dart';
import 'search_controller.dart';

/// Shared lazy result list, including first-page and pagination failure states.
class PlaceSearchResults extends StatelessWidget {
  const PlaceSearchResults({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onLoadMore,
    required this.onReset,
    this.onOpen,
    this.insetCards = false,
    this.openRealPlacesOnMap = false,
    this.emptyState,
  });
  final PlaceSearchState state;
  final VoidCallback onRetry, onLoadMore, onReset;
  final VoidCallback? onOpen;
  final bool insetCards;
  final bool openRealPlacesOnMap;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      if (state.isLoading)
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                AppRestaurantSkeleton(),
                SizedBox(height: 12),
                AppRestaurantSkeleton(),
              ],
            ),
          ),
        )
      else if (state.error != null)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: AppErrorState(message: state.error!, onRetry: onRetry),
          ),
        )
      else if (state.items.isEmpty)
        SliverToBoxAdapter(
          child:
              emptyState ??
              AppEmptyState(
                title: 'Không tìm thấy quán phù hợp.',
                message: 'Thử từ khóa khác hoặc bỏ bớt điều kiện lọc.',
                icon: Icons.search_off,
                actionLabel: 'Xóa tìm kiếm và bộ lọc',
                onAction: onReset,
              ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: state.items.length,
            itemBuilder: (_, index) => PlaceCard(
              place: state.items[index],
              onOpen: onOpen,
              openOnMap: openRealPlacesOnMap && !state.isDemo,
              compact: !insetCards,
              insetImage: insetCards,
              imageAspectRatio: insetCards ? 1.85 : 16 / 9,
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(
          child: state.pageError != null
              ? AppErrorState(message: state.pageError!, onRetry: onLoadMore)
              : state.nextCursor == null
              ? const SizedBox.shrink()
              : AppButton(
                  label: 'Tải thêm quán',
                  isLoading: state.isLoadingMore,
                  onPressed: onLoadMore,
                  expanded: true,
                ),
        ),
      ),
    ],
  );
}
