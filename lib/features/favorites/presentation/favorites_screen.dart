import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../places/domain/place.dart';
import '../../places/domain/place_search.dart';
import '../../places/presentation/place_card.dart';
import '../../places/presentation/place_providers.dart';
import 'favorite_providers.dart';

enum _FavoriteSort { recent, rating, name }

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  String _query = '';
  String _category = 'Tất cả';
  _FavoriteSort _sort = _FavoriteSort.recent;

  @override
  Widget build(BuildContext context) {
    final ids = ref.watch(favoriteIdsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Food Review — Favorites'),
            Text('Những địa điểm bạn muốn quay lại'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tìm kiếm yêu thích',
            onPressed: _search,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Sắp xếp yêu thích',
            onPressed: _sortFavorites,
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AuthGate(
          returnTo: AppRoute.favorites.path,
          child: ref
              .watch(placesProvider)
              .when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Đang tải danh sách yêu thích',
                  ),
                ),
                error: (error, _) => AppErrorState(
                  message: AppErrorMessage.from(
                    error,
                    fallback: 'Không tải được danh sách yêu thích.',
                  ),
                  onRetry: () => ref.invalidate(placesProvider),
                ),
                data: (places) => _content(context, ref, places, ids),
              ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    List<Place> places,
    Set<String> ids,
  ) {
    final favorites = places.where((place) => ids.contains(place.id)).toList();
    final categories = <String>{
      'Tất cả',
      ...favorites.map((place) => place.category),
    }.toList();
    final filtered = favorites.where((place) {
      final query = normalizePlaceSearchText(_query);
      final matchesQuery =
          query.isEmpty ||
          normalizePlaceSearchText(
            [place.name, place.address, ...place.foodCategories].join(' '),
          ).contains(query);
      final matchesCategory =
          _category == 'Tất cả' ||
          place.category == _category ||
          place.foodCategories.contains(_category);
      return matchesQuery && matchesCategory;
    }).toList();
    filtered.sort((a, b) {
      final order = switch (_sort) {
        _FavoriteSort.recent => a.id.compareTo(b.id),
        _FavoriteSort.rating => b.averageRating.compareTo(a.averageRating),
        _FavoriteSort.name => a.name.compareTo(b.name),
      };
      return order == 0 ? a.id.compareTo(b.id) : order;
    });

    if (favorites.isEmpty) {
      return _EmptyFavorites(onExplore: () => context.go(AppRoute.home.path));
    }
    return CustomScrollView(
      key: const PageStorageKey('favorites-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.md,
              AppSpacing.margin,
              AppSpacing.sm,
            ),
            child: _CollectionSummary(count: favorites.length),
          ),
        ),
        SliverToBoxAdapter(
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push(AppRoute.wantToVisit.path),
              icon: const Icon(Icons.bookmark_border),
              label: const Text('Danh sách muốn ghé'),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                return AppChip(
                  label: category,
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                );
              },
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _FilterEmpty(
              onReset: () => setState(() => _category = 'Tất cả'),
            ),
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
              itemBuilder: (context, index) => PlaceCard(
                key: ValueKey(filtered[index].id),
                place: filtered[index],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _search() async {
    final query = await showDialog<String>(
      context: context,
      builder: (_) => const _FavoriteSearchDialog(),
    );
    if (query != null && mounted) setState(() => _query = query);
  }

  Future<void> _sortFavorites() async {
    final selected = await showModalBottomSheet<_FavoriteSort>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Sắp xếp theo')),
            for (final sort in _FavoriteSort.values)
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

  String _sortLabel(_FavoriteSort sort) => switch (sort) {
    _FavoriteSort.recent => 'Mới lưu gần đây',
    _FavoriteSort.rating => 'Đánh giá cao nhất',
    _FavoriteSort.name => 'Tên A–Z',
  };
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.bookmark_added, color: context.colors.onPrimaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bộ sưu tập cá nhân',
                  style: context.textStyles.titleMedium?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
                Text(
                  '$count địa điểm đã lưu',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.favorite, color: context.colors.onPrimaryContainer),
        ],
      ),
    ),
  );
}

class _FavoriteSearchDialog extends StatefulWidget {
  const _FavoriteSearchDialog();

  @override
  State<_FavoriteSearchDialog> createState() => _FavoriteSearchDialogState();
}

class _FavoriteSearchDialogState extends State<_FavoriteSearchDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tìm trong yêu thích'),
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

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    children: [
      const SizedBox(height: 72),
      const AppEmptyState(
        title: 'Bạn chưa lưu nhà hàng nào',
        message: 'Lưu những địa điểm yêu thích để dễ dàng tìm lại khi cần.',
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
          'Bạn chưa lưu quán ăn thuộc danh mục hoặc từ khóa này.',
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
