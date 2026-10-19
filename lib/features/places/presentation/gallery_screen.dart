import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/gallery.dart';
import '../domain/place.dart';
import 'gallery_providers.dart';
import 'gallery_viewer.dart';
import 'gallery_widgets.dart';
import 'place_detail_actions.dart';
import 'place_providers.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key, required this.request});
  final GalleryRequest request;
  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final _scroll = ScrollController();
  PhotoCategory? _category;
  bool _opened = false;
  @override
  void didUpdateWidget(covariant GalleryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request != widget.request) {
      _category = null;
      _opened = false;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _location([int? index]) => AppRoute.gallery.location(
    parameters: {'restaurantId': widget.request.placeId},
    query: {
      if (widget.request.fromReview) 'source': 'review',
      if (widget.request.fromReview && widget.request.reviewId != null)
        'reviewId': widget.request.reviewId!,
      if (index != null) 'index': '$index',
    },
  );
  void _viewer(
    Place place,
    GalleryCollection collection,
    List<GalleryPhoto> photos,
    GalleryPhoto selected,
  ) {
    showGalleryViewer(
      context,
      photos: photos,
      index: photos.indexOf(selected),
      onShare: (photo) => showPlaceShare(
        context,
        place,
        location: _location(collection.photos.indexOf(photo)),
      ),
    );
  }

  void _upload() => showAppBottomSheet<void>(
    context,
    title: 'Đóng góp ảnh',
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Đăng ảnh trực tiếp chưa được tích hợp. Luồng viết đánh giá và tải ảnh sẽ được triển khai ở T13; hiện chưa gửi hay lưu ảnh.',
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Mở màn viết đánh giá',
          onPressed: () {
            Navigator.pop(sheetContext);
            context.push(
              AppRoute.createReview.location(
                parameters: {'restaurantId': widget.request.placeId},
              ),
            );
          },
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeProvider(widget.request.placeId));
    final place = state.asData?.value;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: const RouteBackButton(),
        centerTitle: true,
        titleSpacing: 0,
        title: Column(
          children: [
            Text(
              'Thư viện ảnh',
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
            tooltip: 'Chia sẻ thư viện',
            onPressed: place == null
                ? null
                : () => showPlaceShare(context, place, location: _location()),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Cá nhân',
            onPressed: () => context.push(AppRoute.profile.path),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: context.colors.primary,
              child: Icon(
                Icons.person_outline,
                color: context.colors.onPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: () => const Padding(
            padding: AppSpacing.page,
            child: AppSkeleton(height: 300),
          ),
          error: (error, _) => AppErrorState(
            message: AppErrorMessage.from(error),
            onRetry: () =>
                ref.invalidate(placeProvider(widget.request.placeId)),
          ),
          data: (place) => place == null
              ? const AppEmptyState(
                  title: 'Không tìm thấy quán.',
                  message: 'Vui lòng quay lại và chọn một quán khác.',
                )
              : _gallery(place),
        ),
      ),
    );
  }

  Widget _gallery(Place place) => ref
      .watch(galleryProvider(widget.request))
      .when(
        loading: () => const Padding(
          padding: AppSpacing.page,
          child: AppSkeleton(height: 300),
        ),
        error: (error, _) => AppErrorState(
          message: AppErrorMessage.from(
            error,
            fallback: 'Không tải được thư viện ảnh.',
          ),
          onRetry: () => ref.invalidate(galleryProvider(widget.request)),
        ),
        data: (collection) {
          if (collection.photos.isEmpty) {
            return AppEmptyState(
              title: 'Chưa có ảnh',
              message: 'Chưa có ảnh cho nội dung này.',
              actionLabel: 'Đóng góp ảnh',
              onAction: _upload,
            );
          }
          if (!_opened && widget.request.index != null) {
            _opened = true;
            final request = widget.request;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.request == request) {
                _viewer(
                  place,
                  collection,
                  collection.photos,
                  collection.photos[collection.safeIndex(request.index)],
                );
              }
            });
          }
          final featured = collection.photos.first;
          final filtered = collection.photos
              .where((p) => _category == null || p.category == _category)
              .toList();
          final grid = filtered
              .where((photo) => !identical(photo, featured))
              .toList();
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GalleryFeatured(
                            photo: featured,
                            count: collection.photos.length,
                            onTap: () => _viewer(
                              place,
                              collection,
                              collection.photos,
                              featured,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final category in [
                                  null,
                                  PhotoCategory.food,
                                  PhotoCategory.space,
                                  PhotoCategory.guests,
                                  PhotoCategory.other,
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: AppChip(
                                      label:
                                          '${category?.label ?? 'Tất cả'} (${collection.photos.where((p) => category == null || p.category == category).length})',
                                      selected: _category == category,
                                      onSelected: (_) =>
                                          setState(() => _category = category),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (place.isDemo ||
                              collection.photos.any((photo) => photo.isDemo))
                            Text(
                              'Ảnh minh họa · Không phải ảnh quán đã xác minh',
                              style: context.textStyles.labelSmall,
                            ),
                          if (widget.request.fromReview)
                            Text(
                              'Ảnh từ đánh giá đã chọn',
                              style: context.textStyles.labelSmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (grid.isEmpty && filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: AppEmptyState(
                        title: 'Chưa có ảnh thuộc loại này',
                        message: 'Hãy chọn loại ảnh khác.',
                        actionLabel: 'Xem tất cả',
                        onAction: () => setState(() => _category = null),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: (grid.length / 2).ceil(),
                        itemBuilder: (_, row) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var col = 0; col < 2; col++) ...[
                                if (col > 0) const SizedBox(width: 12),
                                Expanded(
                                  child: row * 2 + col >= grid.length
                                      ? const SizedBox.shrink()
                                      : GalleryTile(
                                          key: ValueKey(
                                            'gallery-tile-${row * 2 + col}',
                                          ),
                                          photo: grid[row * 2 + col],
                                          onTap: () => _viewer(
                                            place,
                                            collection,
                                            filtered,
                                            grid[row * 2 + col],
                                          ),
                                        ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: GalleryContribution(onUpload: _upload),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
