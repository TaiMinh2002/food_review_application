import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_search.dart';
import 'want_to_visit_providers.dart';

enum _WantSort { recent, rating, distance }

class WantToVisitScreen extends ConsumerStatefulWidget {
  const WantToVisitScreen({super.key});

  @override
  ConsumerState<WantToVisitScreen> createState() => _WantToVisitScreenState();
}

class _WantToVisitScreenState extends ConsumerState<WantToVisitScreen> {
  String _query = '';
  _WantSort _sort = _WantSort.recent;

  @override
  Widget build(BuildContext context) {
    final ids = ref.watch(wantToVisitIdsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cá Nhân'),
            Text('Lưu lại những nơi bạn muốn trải nghiệm'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tìm trong danh sách muốn ghé',
            onPressed: _search,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Sắp xếp danh sách muốn ghé',
            onPressed: _sortPlaces,
            icon: const Icon(Icons.tune),
          ),
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: CircleAvatar(child: Icon(Icons.person, size: 18)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AuthGate(
          returnTo: AppRoute.wantToVisit.path,
          child: ref
              .watch(wantToVisitPlacesProvider)
              .when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Đang tải danh sách muốn ghé',
                  ),
                ),
                error: (error, _) => AppErrorState(
                  message: AppErrorMessage.from(
                    error,
                    fallback: 'Không tải được danh sách muốn ghé.',
                  ),
                  onRetry: () => ref.invalidate(wantToVisitPlacesProvider),
                ),
                data: (places) => _content(context, places, ids),
              ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<Place> places, Set<String> ids) {
    final saved = places.where((place) => ids.contains(place.id)).toList();
    final query = normalizePlaceSearchText(_query);
    final filtered = saved.where((place) {
      if (query.isEmpty) return true;
      return normalizePlaceSearchText(
        [place.name, place.address, ...place.foodCategories].join(' '),
      ).contains(query);
    }).toList();
    filtered.sort((a, b) {
      final result = switch (_sort) {
        _WantSort.recent => a.id.compareTo(b.id),
        _WantSort.rating => b.averageRating.compareTo(a.averageRating),
        _WantSort.distance => a.address.compareTo(b.address),
      };
      return result == 0 ? a.id.compareTo(b.id) : result;
    });
    if (saved.isEmpty) return _EmptyWantToVisit(onExplore: _explore);
    return CustomScrollView(
      key: const PageStorageKey('want-to-visit-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.md,
              AppSpacing.margin,
              AppSpacing.sm,
            ),
            child: _VisitSummary(count: saved.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    query.isEmpty ? 'Mới thêm' : 'Kết quả tìm kiếm',
                    style: context.textStyles.titleMedium,
                  ),
                ),
                Text(
                  '${filtered.length} địa điểm',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _FilterEmpty(onReset: () => setState(() => _query = '')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.md,
              AppSpacing.margin,
              AppSpacing.xxl,
            ),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  _WantPlaceCard(place: filtered[index]),
            ),
          ),
      ],
    );
  }

  void _explore() => context.go(AppRoute.home.path);

  Future<void> _search() async {
    final query = await showDialog<String>(
      context: context,
      builder: (_) => const _WantSearchDialog(),
    );
    if (query != null && mounted) setState(() => _query = query);
  }

  Future<void> _sortPlaces() async {
    final selected = await showModalBottomSheet<_WantSort>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Sắp xếp theo')),
            for (final sort in _WantSort.values)
              ListTile(
                title: Text(_sortLabel(sort)),
                trailing: Icon(
                  sort == _sort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                onTap: () => Navigator.pop(context, sort),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _sort = selected);
  }

  String _sortLabel(_WantSort sort) => switch (sort) {
    _WantSort.recent => 'Mới thêm',
    _WantSort.rating => 'Đánh giá cao',
    _WantSort.distance => 'Khoảng cách gần',
  };
}

class _WantPlaceCard extends ConsumerWidget {
  const _WantPlaceCard({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(wantToVisitIdsProvider).contains(place.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppRestaurantCard(
        name: place.name,
        category: place.foodCategories.firstOrNull ?? place.category,
        address: place.address,
        imageUrl: place.imageUrls.firstOrNull,
        rating: place.averageRating,
        reviewCount: place.reviewCount,
        compact: true,
        isFavorite: saved,
        favoriteIcon: Icons.bookmark,
        favoriteBorderIcon: Icons.bookmark_border,
        favoriteLabel: saved ? 'Bỏ khỏi muốn ghé' : 'Thêm vào muốn ghé',
        onTap: () => context.push(
          AppRoute.restaurant.location(parameters: {'restaurantId': place.id}),
        ),
        onFavorite: () => requestWantToVisit(context, ref, place.id),
      ),
    );
  }
}

class _VisitSummary extends StatelessWidget {
  const _VisitSummary({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.bookmark, color: context.colors.onPrimaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danh sách của bạn',
                  style: context.textStyles.titleMedium?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
                Text(
                  '$count địa điểm đang chờ bạn khám phá',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.explore, color: context.colors.onPrimaryContainer),
        ],
      ),
    ),
  );
}

class _WantSearchDialog extends StatefulWidget {
  const _WantSearchDialog();
  @override
  State<_WantSearchDialog> createState() => _WantSearchDialogState();
}

class _WantSearchDialogState extends State<_WantSearchDialog> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tìm trong danh sách'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: const InputDecoration(
        labelText: 'Tên quán hoặc khu vực',
        prefixIcon: Icon(Icons.search),
      ),
      onSubmitted: (value) => Navigator.pop(context, value.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('Tìm'),
      ),
    ],
  );
}

class _EmptyWantToVisit extends StatelessWidget {
  const _EmptyWantToVisit({required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    children: [
      const SizedBox(height: 72),
      const AppEmptyState(
        title: 'Danh sách của bạn đang trống',
        message:
            'Lưu những nhà hàng bạn muốn thử để dễ dàng quay lại khám phá.',
        icon: Icons.bookmark_border,
      ),
      const SizedBox(height: AppSpacing.lg),
      AppButton(
        label: 'Khám phá nhà hàng',
        icon: Icons.explore_outlined,
        expanded: true,
        onPressed: onExplore,
      ),
    ],
  );
}

class _FilterEmpty extends StatelessWidget {
  const _FilterEmpty({required this.onReset});
  final VoidCallback onReset;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 44, color: context.colors.primary),
        const SizedBox(height: AppSpacing.md),
        Text('Không có kết quả', style: context.textStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Không tìm thấy địa điểm phù hợp trong danh sách của bạn.',
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(onPressed: onReset, child: const Text('Xem tất cả')),
      ],
    ),
  );
}
