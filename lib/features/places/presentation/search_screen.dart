import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/place_search.dart';
import 'search_results.dart';
import 'search_controller.dart';
import 'search_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.seed});
  final SearchSeed seed;
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _text;
  final _scroll = ScrollController();
  final _resultsKey = GlobalKey();
  PlaceSearchController get _controller =>
      ref.read(searchControllerProvider(widget.seed).notifier);

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.seed.request.query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(recentSearchesProvider.notifier).remember(_text.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed) {
      _text.text = widget.seed.request.query;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _remember() =>
      ref.read(recentSearchesProvider.notifier).remember(_text.text);

  void _submit() {
    FocusScope.of(context).unfocus();
    _remember();
    _controller.submit(_text.text);
    final target = _resultsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  void _recent(String query) {
    _text.text = query;
    _controller.submit(query);
    _remember();
  }

  void _reset() {
    _text.clear();
    _controller.reset();
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _filters() async {
    FocusScope.of(context).unfocus();
    final request = ref.read(searchControllerProvider(widget.seed)).request;
    final result = await context.push<PlaceSearchRequest>(
      AppRoute.filters.location(query: request.queryParameters),
    );
    if (!mounted || result == null) return;
    _text.text = result.query;
    _controller.apply(result);
    _remember();
  }

  Future<void> _sort() async {
    final request = ref.read(searchControllerProvider(widget.seed)).request;
    final result = await showSearchSort(context, request.sort);
    if (mounted && result != null) _controller.setSort(result);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider(widget.seed));
    final request = state.request;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: const RouteBackButton(),
        title: const Text('Tìm Kiếm'),
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
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : SearchBottomBar(
              onReset: _reset,
              onSubmit: _submit,
              label: 'Tìm kiếm',
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
              key: const PageStorageKey('search-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSearchField(
                          controller: _text,
                          onChanged: _controller.setQuery,
                          onSubmitted: (_) => _submit(),
                          onFilter: _filters,
                          filterCount: request.activeFilterCount,
                        ),
                        const SizedBox(height: 8),
                        SearchActiveFilters(
                          request: request,
                          onChanged: _controller.apply,
                        ),
                        const SizedBox(height: 16),
                        SearchRecentSection(onSelected: _recent),
                        const SizedBox(height: 24),
                        if (state.categories.isNotEmpty ||
                            request.categories.isNotEmpty) ...[
                          SearchCategorySection(
                            categories: state.categories,
                            selected: request.categories,
                            onToggle: _controller.toggleCategory,
                          ),
                          const SizedBox(height: 24),
                        ],
                        Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Icon(
                              Icons.tune,
                              color: context.colors.primary,
                            ),
                            title: const Text('Bộ lọc chi tiết'),
                            subtitle: const Text(
                              'Đánh giá, khoảng giá và tiện ích',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _filters,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state.isDemo)
                          Text(
                            'Dữ liệu minh họa · Yêu thích và lịch sử lưu trong phiên',
                            style: context.textStyles.labelSmall?.copyWith(
                              color: context.colors.secondary,
                            ),
                          ),
                        const SizedBox(height: 16),
                        AppSectionHeader(
                          key: _resultsKey,
                          title: 'Kết quả tìm kiếm',
                          subtitle: state.isLoading
                              ? 'Đang tìm quán phù hợp…'
                              : state.totalCount == null
                              ? '${state.items.length} quán đã tải'
                              : '${state.totalCount} quán phù hợp',
                          actionLabel: 'Sắp xếp',
                          onAction: _sort,
                        ),
                        Text(
                          request.sort.label,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
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
                  onOpen: _remember,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
