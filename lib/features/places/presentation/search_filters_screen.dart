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
    final options = ref.watch(searchOptionsProvider);
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
                  sort: widget.initialRequest.categoryScope == null
                      ? PlaceSearchSort.relevance
                      : PlaceSearchSort.rating,
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
                    onRetry: () => ref.invalidate(searchOptionsProvider),
                  ),
                  data: (page) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if ((PlaceCategory.byId(_draft.categoryScope)
                                      ?.subcategories ??
                                  page.categories)
                              .isNotEmpty ||
                          _draft.categories.isNotEmpty) ...[
                        SearchCategorySection(
                          categories:
                              PlaceCategory.byId(_draft.categoryScope)
                                  ?.subcategories ??
                              page.categories,
                          selected: _draft.categories,
                          onToggle: _toggleCategory,
                        ),
                        const SizedBox(height: 24),
                      ],
                      const AppSectionHeader(title: 'Bộ lọc chi tiết'),
                      const SizedBox(height: 12),
                      _FilterGroup(
                        title: 'Đánh giá',
                        child: _ChoiceGrid(
                          choices: [
                            for (final rating in <double?>[null, 3, 4, 4.5])
                              (
                                label: rating == null
                                    ? 'Tất cả'
                                    : 'Từ ${rating == rating.roundToDouble() ? rating.toInt() : rating} sao ★',
                                selected: _draft.minRating == rating,
                                onTap: () => _change(
                                  _draft.copyWith(
                                    minRating: rating,
                                    clearRating: rating == null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FilterGroup(
                        title: 'Khoảng giá (VND)',
                        subtitle: 'Khoảng giá quán có giao với mức chọn',
                        child: _ChoiceGrid(
                          choices: [
                            for (final range
                                in const <({String label, int? min, int? max})>[
                                  (
                                    label: 'Dưới 50.000đ',
                                    min: null,
                                    max: 49999,
                                  ),
                                  (
                                    label: '50.000đ – 100.000đ',
                                    min: 50000,
                                    max: 100000,
                                  ),
                                  (
                                    label: '100.000đ – 200.000đ',
                                    min: 100000,
                                    max: 200000,
                                  ),
                                  (
                                    label: 'Trên 200.000đ',
                                    min: 200001,
                                    max: null,
                                  ),
                                ])
                              (
                                label: range.label,
                                selected:
                                    _draft.minPrice == range.min &&
                                    _draft.maxPrice == range.max,
                                onTap: () => _change(
                                  _draft.copyWith(
                                    clearPrice: true,
                                    minPrice: range.min,
                                    maxPrice: range.max,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FilterGroup(
                        title: 'Khoảng cách',
                        subtitle: 'Chưa có vị trí để tính khoảng cách.',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            AppChip(
                              label: '< 1 km',
                              icon: Icons.near_me_outlined,
                            ),
                            AppChip(
                              label: '< 3 km',
                              icon: Icons.near_me_outlined,
                            ),
                            AppChip(
                              label: '< 5 km',
                              icon: Icons.near_me_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FilterGroup(
                        title: 'Giờ phục vụ và tiện ích',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Đang mở cửa'),
                              subtitle: Text(
                                'Chưa có lịch phục vụ được xác minh',
                              ),
                              value: false,
                              onChanged: null,
                            ),
                            const Divider(),
                            const Text('Tiện ích đi kèm'),
                            const SizedBox(height: 8),
                            if (page.amenities.isEmpty)
                              const Text('Chưa có thông tin tiện ích.')
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  for (final amenity in page.amenities)
                                    AppChip(
                                      label: amenity,
                                      selected: _draft.amenities.contains(
                                        amenity,
                                      ),
                                      onSelected: (selected) {
                                        final values = {..._draft.amenities};
                                        if (selected) {
                                          values.add(amenity);
                                        } else {
                                          values.remove(amenity);
                                        }
                                        _change(
                                          _draft.copyWith(amenities: values),
                                        );
                                      },
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const AppSectionHeader(title: 'Sắp xếp theo'),
                      const SizedBox(height: 12),
                      SearchSortChoices(
                        selected: _draft.sort,
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

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.choices});
  final List<({String label, bool selected, VoidCallback onTap})> choices;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth < 240 ||
              MediaQuery.textScalerOf(context).scale(14) > 20
          ? 1
          : 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final choice in choices)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 8) / columns,
              child: FilledButton.tonal(
                onPressed: choice.onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: choice.selected
                      ? context.colors.primary
                      : context.colors.surfaceContainerLow,
                  foregroundColor: choice.selected
                      ? context.colors.onPrimary
                      : context.colors.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  minimumSize: const Size(48, 48),
                ),
                child: Text(choice.label, textAlign: TextAlign.center),
              ),
            ),
        ],
      );
    },
  );
}
