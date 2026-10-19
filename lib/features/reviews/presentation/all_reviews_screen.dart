import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../../places/domain/place.dart';
import '../../places/presentation/place_detail_actions.dart';
import '../../places/presentation/place_providers.dart';
import 'restaurant_review_card.dart';
import 'review_feed_controller.dart';
import 'review_feed_widgets.dart';

class AllReviewsScreen extends ConsumerStatefulWidget {
  const AllReviewsScreen({super.key, required this.seed});
  final ReviewFeedSeed seed;
  @override
  ConsumerState<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends ConsumerState<AllReviewsScreen> {
  final _scroll = ScrollController();
  ReviewFeedController get _controller =>
      ref.read(reviewFeedControllerProvider(widget.seed).notifier);
  @override
  void didUpdateWidget(covariant AllReviewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed && _scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _write() async {
    final seed = widget.seed;
    final saved = await context.push<bool>(
      AppRoute.createReview.location(
        parameters: {'restaurantId': seed.placeId},
      ),
    );
    if (mounted && widget.seed == seed && saved == true) {
      _controller.refreshSummary();
      _controller.retry();
    }
  }

  Future<void> _filters() async {
    final seed = widget.seed;
    final state = ref.read(reviewFeedControllerProvider(seed));
    final result = await showReviewFilterSheet(
      context,
      state.filters,
      state.summary.asData?.value,
    );
    if (mounted && widget.seed == seed && result != null) {
      _controller.apply(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeState = ref.watch(placeProvider(widget.seed.placeId));
    final place = placeState.asData?.value;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: const RouteBackButton(),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tất cả đánh giá',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.titleMedium,
            ),
            Text(
              place?.name ?? 'Thông tin quán',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lọc và sắp xếp',
            onPressed: place == null ? null : _filters,
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            tooltip: 'Chia sẻ',
            icon: const Icon(Icons.share_outlined),
            onPressed: place == null
                ? null
                : () {
                    final filters = ref
                        .read(reviewFeedControllerProvider(widget.seed))
                        .filters;
                    showPlaceShare(
                      context,
                      place,
                      location: AppRoute.reviews.location(
                        parameters: {'restaurantId': place.id},
                        query: filters.queryParameters,
                      ),
                    );
                  },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: place == null
          ? null
          : ReviewWriteBar(onWrite: _write),
      body: SafeArea(
        top: false,
        bottom: false,
        child: placeState.when(
          loading: () => const Padding(
            padding: AppSpacing.page,
            child: AppSkeleton(height: 220),
          ),
          error: (error, _) => AppErrorState(
            message: AppErrorMessage.from(
              error,
              fallback: 'Không tải được thông tin quán.',
            ),
            onRetry: () => ref.invalidate(placeProvider(widget.seed.placeId)),
          ),
          data: (place) => place == null
              ? const AppEmptyState(
                  title: 'Không tìm thấy quán.',
                  message: 'Vui lòng quay lại và chọn một quán khác.',
                  icon: Icons.storefront_outlined,
                )
              : _content(place),
        ),
      ),
    );
  }

  Widget _content(Place place) {
    final state = ref.watch(reviewFeedControllerProvider(widget.seed));
    final summary = state.summary.asData?.value;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: CustomScrollView(
          controller: _scroll,
          key: PageStorageKey('reviews-${widget.seed.placeId}'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    state.summary.when(
                      loading: () => const AppSkeleton(height: 240),
                      error: (error, _) => AppErrorState(
                        key: const ValueKey('summary-error'),
                        message: AppErrorMessage.from(
                          error,
                          fallback: 'Không tải được tổng quan đánh giá.',
                        ),
                        onRetry: _controller.refreshSummary,
                      ),
                      data: (value) => ReviewSummaryCard(summary: value),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Viết đánh giá của bạn',
                      icon: Icons.rate_review_outlined,
                      onPressed: _write,
                    ),
                    const SizedBox(height: 12),
                    ReviewFilterChips(
                      filters: state.filters,
                      summary: summary,
                      onChanged: _controller.apply,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Sắp xếp theo:',
                          style: context.textStyles.labelSmall,
                        ),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: _filters,
                              icon: const Icon(Icons.expand_more, size: 16),
                              label: Text(state.filters.sort.label),
                            ),
                            const Tooltip(
                              message: 'Chưa có dữ liệu lượt hữu ích',
                              child: TextButton(
                                onPressed: null,
                                child: Text('Hữu ích nhất'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (place.isDemo || state.isDemo || summary?.isDemo == true)
                      Text(
                        'Đánh giá minh họa · Chưa phải số liệu thực tế',
                        style: context.textStyles.labelSmall,
                      ),
                    if (state.filters.activeCount > 0)
                      TextButton(
                        onPressed: _controller.reset,
                        child: const Text('Bỏ bộ lọc đánh giá'),
                      ),
                    if (!state.loading && state.error == null)
                      Text(
                        state.totalCount == null
                            ? '${state.items.length} đánh giá đã tải'
                            : '${state.totalCount} đánh giá phù hợp',
                        style: context.textStyles.labelSmall,
                      ),
                  ],
                ),
              ),
            ),
            if (state.loading)
              const SliverPadding(
                padding: AppSpacing.page,
                sliver: SliverToBoxAdapter(child: AppSkeleton(height: 220)),
              )
            else if (state.error != null)
              SliverPadding(
                padding: AppSpacing.page,
                sliver: SliverToBoxAdapter(
                  child: AppErrorState(
                    key: const ValueKey('feed-error'),
                    message: state.error!,
                    onRetry: _controller.retry,
                  ),
                ),
              )
            else if (state.items.isEmpty)
              SliverToBoxAdapter(
                child: AppEmptyState(
                  title: 'Chưa có đánh giá phù hợp',
                  message: state.filters.activeCount > 0
                      ? 'Thử bỏ bớt điều kiện lọc.'
                      : 'Hãy là người đầu tiên chia sẻ cảm nhận.',
                  icon: Icons.rate_review_outlined,
                  actionLabel: state.filters.activeCount > 0
                      ? 'Xóa bộ lọc'
                      : 'Viết đánh giá đầu tiên',
                  onAction: state.filters.activeCount > 0
                      ? _controller.reset
                      : _write,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: state.items.length,
                  itemBuilder: (_, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: RestaurantReviewCard(
                      review: state.items[index],
                      expandedImages: true,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: AppSpacing.page,
              sliver: SliverToBoxAdapter(
                child: state.pageError != null
                    ? AppErrorState(
                        key: const ValueKey('page-error'),
                        message: state.pageError!,
                        onRetry: _controller.loadMore,
                      )
                    : state.nextCursor == null
                    ? const SizedBox.shrink()
                    : AppButton(
                        label: 'Tải thêm đánh giá',
                        isLoading: state.loadingMore,
                        onPressed: _controller.loadMore,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
