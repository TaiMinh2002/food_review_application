import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/widgets/app_message.dart';
import '../../favorites/presentation/favorite_providers.dart';
import '../domain/place.dart';
import 'place_detail_actions.dart';
import 'place_detail_overview.dart';
import 'place_detail_sections.dart';
import 'place_providers.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});
  final String placeId;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  final _menuKey = GlobalKey();
  int _photoIndex = 0;

  @override
  void didUpdateWidget(covariant PlaceDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeId != widget.placeId) _photoIndex = 0;
  }

  void _map(Place place) =>
      context.go(AppRoute.map.location(query: {'restaurantId': place.id}));

  void _gallery(Place place) => context.push(
    AppRoute.gallery.location(
      parameters: {'restaurantId': place.id},
      query: {'index': '$_photoIndex'},
    ),
  );

  Future<void> _menu() async {
    final target = _menuKey.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        alignment: .05,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeProvider(widget.placeId));
    final place = state.asData?.value;
    final favorite = ref.watch(favoriteIdsProvider).contains(widget.placeId);
    void toggleFavorite() => requestFavorite(context, ref, widget.placeId);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: const RouteBackButton(),
        title: const Text(
          'Chi tiết quán',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (place != null) ...[
            AppIconButton(
              icon: favorite ? Icons.favorite : Icons.favorite_border,
              tooltip: favorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
              selected: favorite,
              circular: true,
              onPressed: toggleFavorite,
            ),
            IconButton(
              tooltip: 'Chia sẻ quán',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => showPlaceShare(context, place),
            ),
            PopupMenuButton<String>(
              tooltip: 'Tùy chọn quán',
              onSelected: (_) => context.push(
                AppRoute.createReport.location(
                  query: {'targetType': 'place', 'restaurantId': place.id},
                ),
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'report', child: Text('Báo cáo quán')),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: place == null
          ? null
          : PlaceDetailPriceBar(place: place, onDirections: () => _map(place)),
      body: SafeArea(
        top: false,
        bottom: place == null,
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Đang tải thông tin quán',
            ),
          ),
          error: (error, stack) => AppMessage(
            message: AppErrorMessage.from(
              error,
              fallback: 'Không tải được thông tin quán.',
            ),
            onRetry: () => ref.invalidate(placeProvider(widget.placeId)),
          ),
          data: (place) {
            if (place == null) {
              return const AppMessage(message: 'Quán không tồn tại.');
            }
            return CustomScrollView(
              key: PageStorageKey('detail-scroll-${place.id}'),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PlaceDetailOverview(
                            place: place,
                            photoIndex: _photoIndex,
                            onPhotoChanged: (index) =>
                                setState(() => _photoIndex = index),
                            onGallery: () => _gallery(place),
                            onMap: () => _map(place),
                            quickActions: PlaceDetailQuickActions(
                              favorite: favorite,
                              onFavorite: toggleFavorite,
                              onShare: () => showPlaceShare(context, place),
                              onMenu: _menu,
                              onContact: () => showPlaceContact(context),
                            ),
                          ),
                          PlaceStorySection(place: place),
                          PlaceMenuSection(key: _menuKey, place: place),
                          PlaceReviewsSection(
                            place: place,
                            onWriteReview: () => context.push(
                              AppRoute.createReview.location(
                                parameters: {'restaurantId': place.id},
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
