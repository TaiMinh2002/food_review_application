import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/place_search.dart';
import 'search_controller.dart';

class SearchRecentSection extends ConsumerWidget {
  const SearchRecentSection({super.key, required this.onSelected});
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Tìm kiếm gần đây',
          subtitle: 'Trong phiên này',
          actionLabel: 'Xóa tất cả',
          onAction: recent.isEmpty
              ? null
              : () => ref.read(recentSearchesProvider.notifier).clear(),
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Text(
            'Chưa có tìm kiếm gần đây.',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final query in recent)
                InputChip(
                  label: Text(query),
                  onPressed: () => onSelected(query),
                  onDeleted: () =>
                      ref.read(recentSearchesProvider.notifier).remove(query),
                  deleteButtonTooltipMessage: 'Xóa tìm kiếm $query',
                ),
            ],
          ),
      ],
    );
  }
}

class SearchCategorySection extends StatelessWidget {
  const SearchCategorySection({
    super.key,
    required this.categories,
    required this.selected,
    required this.onToggle,
  });
  final List<String> categories;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const AppSectionHeader(
        title: 'Danh mục món ăn',
        subtitle: 'Có thể chọn nhiều danh mục',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final category in {...categories, ...selected})
            AppChip(
              label: category,
              selected: selected.contains(category),
              onSelected: (_) => onToggle(category),
              icon: switch (category) {
                'Phở' || 'Món Việt' => Icons.ramen_dining_outlined,
                'Bún' => Icons.soup_kitchen_outlined,
                'Cơm' => Icons.rice_bowl_outlined,
                'Bánh mì' || 'Ăn nhanh' => Icons.bakery_dining_outlined,
                'Đồ nướng' => Icons.outdoor_grill_outlined,
                'Lẩu' => Icons.soup_kitchen_outlined,
                'Cà phê' => Icons.local_cafe_outlined,
                _ => Icons.eco_outlined,
              },
            ),
        ],
      ),
    ],
  );
}

String searchPriceLabel(PlaceSearchRequest request) {
  if (request.minPrice != null && request.maxPrice != null) {
    return AppFormatters.priceRange(request.minPrice!, request.maxPrice!);
  }
  if (request.minPrice != null) {
    return 'Từ ${AppFormatters.price(request.minPrice!)}';
  }
  return 'Đến ${AppFormatters.price(request.maxPrice!)}';
}

class SearchActiveFilters extends StatelessWidget {
  const SearchActiveFilters({super.key, required this.request, this.onChanged});
  final PlaceSearchRequest request;
  final ValueChanged<PlaceSearchRequest>? onChanged;
  @override
  Widget build(BuildContext context) {
    final filters = <(String, PlaceSearchRequest)>[
      for (final category in request.categories)
        (
          category,
          request.copyWith(
            categories: {...request.categories}..remove(category),
          ),
        ),
      if (request.minRating != null)
        (
          'Từ ${request.minRating! == request.minRating!.roundToDouble() ? request.minRating!.toInt() : request.minRating} sao',
          request.copyWith(clearRating: true),
        ),
      if (request.minPrice != null || request.maxPrice != null)
        (searchPriceLabel(request), request.copyWith(clearPrice: true)),
      for (final amenity in request.amenities)
        (
          amenity,
          request.copyWith(amenities: {...request.amenities}..remove(amenity)),
        ),
      if (request.sort != PlaceSearchSort.relevance)
        (request.sort.label, request.copyWith(sort: PlaceSearchSort.relevance)),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final (label, value) in filters)
          InputChip(
            label: Text(label),
            selected: true,
            onDeleted: onChanged == null ? null : () => onChanged!(value),
            deleteButtonTooltipMessage: 'Bỏ lọc $label',
            labelStyle: context.textStyles.labelSmall?.copyWith(
              color: context.colors.onPrimaryContainer,
            ),
            selectedColor: context.colors.primaryContainer,
          ),
      ],
    );
  }
}

class SearchBottomBar extends StatelessWidget {
  const SearchBottomBar({
    super.key,
    required this.onReset,
    required this.onSubmit,
    required this.label,
    this.icon = Icons.search,
  });
  final VoidCallback onReset;
  final VoidCallback? onSubmit;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Material(
    color: context.semanticColors.canvas,
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final reset = AppButton(
                  label: 'Đặt lại',
                  variant: AppButtonVariant.secondary,
                  onPressed: onReset,
                );
                final submit = AppButton(
                  label: label,
                  icon: icon,
                  onPressed: onSubmit,
                );
                if (constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [reset, const SizedBox(height: 8), submit],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: reset),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: submit),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

Future<PlaceSearchSort?> showSearchSort(
  BuildContext context,
  PlaceSearchSort selected,
) => showAppBottomSheet<PlaceSearchSort>(
  context,
  title: 'Sắp xếp theo',
  builder: (context) => SearchSortChoices(
    selected: selected,
    onSelected: (sort) => Navigator.pop(context, sort),
  ),
);

class SearchSortChoices extends StatelessWidget {
  const SearchSortChoices({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final PlaceSearchSort selected;
  final ValueChanged<PlaceSearchSort> onSelected;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          for (final sort in PlaceSearchSort.values)
            ListTile(
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadii.inputBorder,
              ),
              selected: selected == sort,
              selectedTileColor: context.colors.surfaceContainerLow,
              leading: Icon(switch (sort) {
                PlaceSearchSort.relevance => Icons.auto_awesome_outlined,
                PlaceSearchSort.rating => Icons.star_outline,
                PlaceSearchSort.reviews => Icons.rate_review_outlined,
                PlaceSearchSort.price => Icons.sell_outlined,
              }),
              title: Text(sort.label),
              trailing: Icon(
                selected == sort
                    ? Icons.check_circle_outline
                    : Icons.circle_outlined,
              ),
              onTap: () => onSelected(sort),
            ),
          ListTile(
            enabled: false,
            leading: const Icon(Icons.near_me_outlined),
            title: const Text('Gần tôi nhất'),
            subtitle: const Text('Chưa có dữ liệu vị trí'),
          ),
        ],
      ),
    ),
  );
}
