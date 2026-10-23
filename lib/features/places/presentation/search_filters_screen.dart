import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/place_search.dart';
import '../domain/place_category.dart';
import 'search_controller.dart';
import 'search_widgets.dart';

class SearchFiltersScreen extends ConsumerStatefulWidget {
  const SearchFiltersScreen({super.key, required this.initialRequest});
  final PlaceSearchRequest initialRequest;
  @override
  ConsumerState<SearchFiltersScreen> createState() =>
      _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends ConsumerState<SearchFiltersScreen> {
  late PlaceSearchRequest _draft;
  late final TextEditingController _text;
  @override
  void initState() {
    super.initState();
    _draft = widget.initialRequest;
    _text = TextEditingController(text: _draft.query);
  }

  @override
  void didUpdateWidget(covariant SearchFiltersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRequest != widget.initialRequest) {
      _draft = widget.initialRequest;
      _text.text = _draft.query;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _change(PlaceSearchRequest request) => setState(() => _draft = request);
  void _toggleCategory(String category) {
    final selected = {..._draft.categories};
    if (!selected.remove(category)) selected.add(category);
    _change(_draft.copyWith(categories: selected));
  }

  void _apply() {
    FocusScope.of(context).unfocus();
    if (context.canPop()) {
      context.pop(_draft);
    } else {
      context.go(AppRoute.search.location(query: _draft.queryParameters));
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(
      searchOptionsProvider(widget.initialRequest.categoryScope),
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: const RouteBackButton(),
        title: const Text('Tìm Kiếm'),
        actions: [
          TextButton(
            onPressed: () => backOrHome(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : SearchBottomBar(
              onReset: () => _change(
                PlaceSearchRequest(
                  query: _draft.query,
                  categoryScope: widget.initialRequest.categoryScope,
                  sort: PlaceSearchSort.relevance,
                ),
              ),
              onSubmit: options.hasValue ? _apply : null,
              label: 'Áp dụng bộ lọc',
              icon: Icons.filter_alt_outlined,
            ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              key: const PageStorageKey('search-filter-scroll'),
              padding: AppSpacing.page,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                AppSearchField(
                  controller: _text,
                  onChanged: (query) => _change(_draft.copyWith(query: query)),
                  onSubmitted: (_) {
                    if (options.hasValue) _apply();
                  },
                ),
                const SizedBox(height: 8),
                if (PlaceCategory.byId(_draft.categoryScope) case final scope?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Trong danh mục ${scope.label}',
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                SearchActiveFilters(request: _draft, onChanged: _change),
                const SizedBox(height: 16),
                SearchRecentSection(
                  onSelected: (query) {
                    _text.text = query;
                    _change(_draft.copyWith(query: query));
                  },
                ),
                const SizedBox(height: 24),
                options.when(
                  loading: () => const AppSkeleton(height: 240),
                  error: (error, stack) => AppErrorState(
                    message: AppErrorMessage.from(
                      error,
                      fallback: 'Không tải được lựa chọn bộ lọc.',
                    ),
                    onRetry: () => ref.invalidate(
                      searchOptionsProvider(
                        widget.initialRequest.categoryScope,
                      ),
                    ),
                  ),
                  data: (page) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_categoryOptions(page).isNotEmpty ||
                          _draft.categories.isNotEmpty) ...[
                        SearchCategorySection(
                          categories: _categoryOptions(page),
                          selected: _draft.categories,
                          onToggle: _toggleCategory,
                        ),
                        const SizedBox(height: 24),
                      ],
                      const AppSectionHeader(title: 'Bộ lọc chi tiết'),
                      const SizedBox(height: 12),
                      const _FilterGroup(
                        title: 'Dữ liệu bộ lọc',
                        subtitle: 'Nguồn OpenStreetMap hiện chỉ xác nhận vị trí, tên và danh mục. Đánh giá, giá, giờ mở cửa và tiện ích sẽ khả dụng khi có nguồn dữ liệu xác thực.',
                        child: Text(
                          'Bán kính tìm kiếm được cố định ở 5 km quanh vị trí đã chọn.',
                        ),
                      ),
                      const SizedBox(height: 24),
                      const AppSectionHeader(title: 'Sắp xếp theo'),
                      const SizedBox(height: 12),
                      SearchSortChoices(
                        selected: _draft.sort,
                        realData: !page.isDemo,
                        onSelected: (sort) =>
                            _change(_draft.copyWith(sort: sort)),
                      ),
                      if (page.isDemo) ...[
                        const SizedBox(height: 24),
                        const AppBadge(
                          label: 'Dữ liệu quán, giá và đánh giá minh họa',
                          tone: AppBadgeTone.accent,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _categoryOptions(PlaceSearchPage page) {
    final scope = PlaceCategory.byId(_draft.categoryScope);
    if (scope == null) return page.categories;
    return scope.subcategories.where(page.categories.contains).toList();
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.textStyles.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}
