import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/widgets/app_message.dart';
import '../domain/place.dart';
import '../domain/place_category.dart';
import '../domain/place_map_repository.dart';
import '../domain/place_search.dart';
import 'home_sections.dart';
import 'place_card.dart';
import 'place_providers.dart';
import 'user_location_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _query = '';
  String? _category;

  void _search() => context.push(
    AppRoute.search.location(
      query: {
        if (_query.trim().isNotEmpty) 'q': _query.trim(),
        'category': ?_category,
      },
    ),
  );

  Future<void> _filters() async {
    final result = await context.push<PlaceSearchRequest>(
      AppRoute.filters.location(
        query: {
          if (_query.trim().isNotEmpty) 'q': _query.trim(),
          'category': ?_category,
        },
      ),
    );
    if (!mounted || result == null) return;
    context.push(AppRoute.search.location(query: result.queryParameters));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 64,
      titleSpacing: AppSpacing.margin,
      title: Row(
        children: [
          Icon(Icons.restaurant, color: context.colors.primary, size: 24),
          const SizedBox(width: AppSpacing.sm),
          const Flexible(
            child: Text(
              'Trang Chủ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
              size: 20,
              color: context.colors.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ref
          .watch(placesProvider)
          .when(
            loading: () => ListView(
              padding: AppSpacing.page,
              children: const [
                AppRestaurantSkeleton(),
                SizedBox(height: 12),
                AppRestaurantSkeleton(),
              ],
            ),
            error: (error, stack) => AppMessage(
              message: AppErrorMessage.from(
                error,
                fallback: 'Không tải được danh sách quán.',
              ),
              onRetry: () => ref.invalidate(placesProvider),
            ),
            data: _content,
          ),
    ),
  );

  Widget _content(List<Place> places) {
    final userPoint = ref.watch(userLocationControllerProvider).point;
    final effectiveLocation = userPoint ?? const GeoPoint(20.9859, 105.7938);
    final isDemoData = places.any((p) => p.isDemo);
    final nearby =
        places
            .where(
              (place) =>
                  isDemoData ||
                  effectiveLocation.distanceTo(
                        GeoPoint(place.latitude, place.longitude),
                      ) <=
                      30000,
            )
            .toList()
          ..sort(
            (a, b) => effectiveLocation
                .distanceTo(GeoPoint(a.latitude, a.longitude))
                .compareTo(
                  effectiveLocation.distanceTo(
                    GeoPoint(b.latitude, b.longitude),
                  ),
                ),
          );
    final filtered = filterPlaces(places, _query, _category);
    final searching = _query.trim().isNotEmpty || _category != null;
    final categories = places.map((p) => p.category).toSet();
    final popular = [...places];
    if (popular.any((p) => p.averageRating > 0)) {
      popular.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    }
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.margin);
    return CustomScrollView(
      key: const PageStorageKey('home-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: HomeGreeting(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: inset,
                    child: AppSearchField(
                      hintText: 'Tìm quán ăn, món ngon...',
                      onChanged: (value) => setState(() => _query = value),
                      onSubmitted: (_) => _search(),
                      onFilter: _filters,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: inset,
                    child: AppSectionHeader(
                      title: 'Danh mục ẩm thực',
                      actionLabel: 'Xem danh mục',
                      onAction: () => context.push(
                        AppRoute.category.location(
                          parameters: {
                            'categoryId':
                                PlaceCategory.byLabel(_category ?? '')?.id ??
                                'nha-hang',
                          },
                        ),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: inset,
                    child: Row(
                      children: [
                        AppChip(
                          label: 'Tất cả',
                          selected: _category == null,
                          onSelected: (_) => setState(() => _category = null),
                        ),
                        for (final category in categories) ...[
                          const SizedBox(width: AppSpacing.sm),
                          AppChip(
                            label: category,
                            icon: _categoryIcon(category),
                            selected: _category == category,
                            onSelected: (selected) => setState(
                              () => _category = selected ? category : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: AppSpacing.page,
                      child: AppMessage(
                        message: 'Không tìm thấy quán phù hợp.',
                      ),
                    )
                  else if (searching) ...[
                    Padding(
                      padding: inset,
                      child: AppSectionHeader(
                        title: 'Kết quả khám phá',
                        subtitle: '${filtered.length} quán phù hợp',
                      ),
                    ),
                    for (final place in filtered.take(20))
                      Padding(
                        padding: inset,
                        child: PlaceCard(place: place),
                      ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: inset,
                      child: AppSectionHeader(
                        title: 'Gợi ý cho bạn',
                        onAction: _search,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: inset,
                      child: PlaceCard(
                        place: filtered.first,
                        compact: false,
                        imageAspectRatio: 16 / 10,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: inset,
                      child: AppSectionHeader(
                        title: 'Quán được yêu thích',
                        onAction: _search,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: inset,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final place
                              in popular
                                  .take(8)
                                  .skip(popular.length > 1 ? 1 : 0))
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.md,
                              ),
                              child: SizedBox(
                                width: 260,
                                child: PlaceCard(
                                  place: place,
                                  compact: false,
                                  imageAspectRatio: 15 / 8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: inset,
                      child: HomeCommunityBanner(
                        onWriteReview: () => showHomeReviewPicker(
                          context,
                          places.take(20).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Padding(
                      padding: inset,
                      child: AppSectionHeader(
                        title: 'Khám phá gần bạn',
                        actionLabel: 'Mở bản đồ',
                        onAction: () => context.go(AppRoute.map.path),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final place in nearby.take(30))
                      Padding(
                        padding: inset,
                        child: PlaceCard(place: place),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
    'Cà phê' => Icons.coffee_outlined,
    'Ăn nhanh' => Icons.lunch_dining_outlined,
    'Khu ẩm thực' => Icons.storefront_outlined,
    'Nhà hàng' => Icons.restaurant_outlined,
    _ => Icons.ramen_dining_outlined,
  };
}
