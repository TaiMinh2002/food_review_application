import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/place_category.dart';
import '../domain/place_search.dart';
import 'category_widgets.dart';
import 'discovery_center.dart';
import 'search_controller.dart';
import 'search_results.dart';
import 'search_widgets.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.uri,
    required this.scope,
  });
  final String categoryId, scope;
  final Uri uri;
  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  late final TextEditingController _text;
  final _scroll = ScrollController();
  bool _showSearch = false;
  SearchSeed get _seed => (
    scope: widget.scope,
    request: PlaceSearchRequest.fromUri(widget.uri).copyWith(
      categoryScope: widget.categoryId,
      sort: widget.uri.queryParameters.containsKey('sort')
          ? PlaceSearchSort.parse(widget.uri.queryParameters['sort'])
          : PlaceSearchSort.relevance,
    ),
  );
  PlaceSearchController get _controller =>
      ref.read(osmSearchControllerProvider(_seed).notifier);

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: _seed.request.query);
    _showSearch = _text.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant CategoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.uri != widget.uri ||
        oldWidget.scope != widget.scope) {
      _text.text = _seed.request.query;
      _showSearch = _text.text.isNotEmpty;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _reset() {
    _text.clear();
    _controller.reset();
  }

  Future<void> _filters() async {
    FocusScope.of(context).unfocus();
    final seed = _seed;
    final request = ref.read(osmSearchControllerProvider(seed)).request;
    final result = await context.push<PlaceSearchRequest>(
      AppRoute.filters.location(query: request.queryParameters),
    );
    if (!mounted || _seed != seed || result == null) return;
    _text.text = result.query;
    if (result.query.isNotEmpty) _showSearch = true;
    _controller.apply(result);
  }

  Future<void> _sort() async {
    final seed = _seed;
    final sort = ref.read(osmSearchControllerProvider(seed)).request.sort;
    final result = await showSearchSort(context, sort, realData: true);
    if (mounted && seed == _seed && result != null) _controller.setSort(result);
  }

  void _openCategory(PlaceCategory category) {
    if (category.id == widget.categoryId) return;
    context.pushReplacement(
      AppRoute.category.location(parameters: {'categoryId': category.id}),
    );
  }

  Widget _unavailable(PlaceCategory category, String message) => Scaffold(
    appBar: AppBar(
      leading: const RouteBackButton(),
      title: const Text('Danh mục ẩm thực'),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CategoryHero(category: category, countLabel: 'Chưa có kết quả'),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: context.textStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            const CategoryDiscoveryStatus(),
            const SizedBox(height: AppSpacing.md),
            CategoryChoices(selectedId: category.id, onSelected: _openCategory),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final category = PlaceCategory.byId(widget.categoryId);
    if (category == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const RouteBackButton(),
          title: const Text('Danh mục ẩm thực'),
        ),
        body: const SafeArea(
          child: AppEmptyState(
            title: 'Danh mục không tồn tại.',
            message: 'Vui lòng quay lại và chọn một danh mục khác.',
            icon: Icons.category_outlined,
          ),
        ),
      );
    }
    if (!category.isOsmSupported) {
      return _unavailable(
        category,
        'OSM chưa phân loại món ăn cho danh mục này. Vui lòng chọn loại quán có dữ liệu bên dưới.',
      );
    }
    if (ref.watch(activeDiscoveryCenterProvider) == null) {
      return _unavailable(
        category,
        'Chọn khu vực để tìm quán trong bán kính 5 km.',
      );
    }
    final state = ref.watch(osmSearchControllerProvider(_seed));
    final request = state.request;
    final filterCount =
        request.activeFilterCount -
        (request.sort == PlaceSearchSort.relevance ? 0 : 1);
    final toolbarButtonStyle = TextButton.styleFrom(
      backgroundColor: context.colors.surfaceContainerLowest,
      textStyle: context.textStyles.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      minimumSize: const Size(0, 44),
    );
    final count = state.isLoading
        ? 'Đang tìm quán…'
        : state.error != null
        ? 'Chưa tải được kết quả'
        : state.totalCount == null
        ? '${state.items.length} quán đã tải'
        : '${state.totalCount} địa điểm trong 5 km';
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        titleSpacing: 20,
        title: Row(
          children: [
            Icon(Icons.restaurant, color: context.colors.primary),
            const SizedBox(width: 8),
            const Text('Trang Chủ'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cá nhân',
            onPressed: () => context.go(AppRoute.profile.path),
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
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: CustomScrollView(
              controller: _scroll,
              key: PageStorageKey('category-${widget.categoryId}'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const RouteBackButton(),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Danh mục ẩm thực',
                                    style: context.textStyles.labelSmall,
                                  ),
                                  Text(
                                    category.label,
                                    style: context.textStyles.headlineSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Tìm kiếm trong danh mục',
                              icon: const Icon(Icons.search),
                              onPressed: () =>
                                  setState(() => _showSearch = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CategoryHero(category: category, countLabel: count),
                        const SizedBox(height: AppSpacing.md),
                        const CategoryDiscoveryStatus(),
                        const SizedBox(height: AppSpacing.md),
                        CategoryChoices(
                          selectedId: category.id,
                          onSelected: _openCategory,
                        ),
                        if (_showSearch) ...[
                          const SizedBox(height: 12),
                          AppSearchField(
                            controller: _text,
                            hintText: 'Tìm trong ${category.label}…',
                            onChanged: _controller.setQuery,
                            onSubmitted: (_) {
                              _controller.submit(_text.text);
                              FocusScope.of(context).unfocus();
                            },
                            onFilter: _filters,
                            filterCount: filterCount,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (category.subcategories.any(state.categories.contains))
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          AppChip(
                            label: 'Tất cả',
                            selected: request.categories.isEmpty,
                            onSelected: (_) => _controller.apply(
                              request.copyWith(categories: {}),
                            ),
                          ),
                          for (final tag in category.subcategories.where(
                            state.categories.contains,
                          )) ...[
                            const SizedBox(width: 6),
                            AppChip(
                              label: tag,
                              selected: request.categories.contains(tag),
                              onSelected: (_) => _controller.apply(
                                request.copyWith(categories: {tag}),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Text(count, style: context.textStyles.titleSmall),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                TextButton.icon(
                                  style: toolbarButtonStyle,
                                  onPressed: _sort,
                                  icon: const Icon(Icons.expand_more, size: 18),
                                  label: Text(switch (request.sort) {
                                    PlaceSearchSort.rating => 'Đánh giá cao',
                                    PlaceSearchSort.relevance =>
                                      'Gần tâm đã chọn',
                                    PlaceSearchSort.reviews => 'Nhiều đánh giá',
                                    PlaceSearchSort.price => 'Giá thấp',
                                  }),
                                ),
                                TextButton.icon(
                                  style: toolbarButtonStyle,
                                  onPressed: _filters,
                                  icon: Badge(
                                    isLabelVisible: filterCount > 0,
                                    label: Text('$filterCount'),
                                    child: const Icon(Icons.tune, size: 18),
                                  ),
                                  label: const Text('Bộ lọc'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SearchActiveFilters(
                          request: request,
                          defaultSort: PlaceSearchSort.relevance,
                          onChanged: _controller.apply,
                        ),
                        if (state.isDemo)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Quán, ảnh, giá và đánh giá minh họa · Yêu thích lưu trong phiên',
                              style: context.textStyles.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                PlaceSearchResults(
                  state: state,
                  onRetry: _controller.retry,
                  onLoadMore: _controller.loadMore,
                  onReset: _reset,
                  insetCards: true,
                  openRealPlacesOnMap: true,
                  emptyState: Column(
                    children: [
                      AppEmptyState(
                        title: 'Chưa tìm thấy nhà hàng',
                        message: 'Không có kết quả phù hợp trong dữ liệu OSM của vùng 5 km. Dữ liệu có thể chưa đầy đủ; thử từ khóa hoặc khu vực khác.',
                        icon: Icons.ramen_dining,
                        actionLabel: 'Xóa bộ lọc',
                        onAction: _reset,
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoute.search.path),
                        child: const Text('Tìm trong tất cả loại quán'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
