import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/formatters/app_formatters.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../../shared/widgets/app_message.dart';
import '../domain/place.dart';
import '../domain/place_map_repository.dart';
import 'discovery_center.dart';
import 'home_sections.dart';
import 'map_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    final center = ref.watch(activeDiscoveryCenterProvider);
    final manual = ref.watch(discoveryCenterProvider);
    final location = ref.watch(userLocationControllerProvider);
    final nearby = ref.watch(homeNearbyPlacesProvider);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpacing.margin,
        title: Row(
          children: [
            Icon(Icons.restaurant, color: context.colors.primary, size: 24),
            const SizedBox(width: AppSpacing.sm),
            const Flexible(child: Text('Trang Chủ')),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cá nhân',
            onPressed: () => context.go(AppRoute.profile.path),
            icon: Icon(Icons.person_outline, color: context.colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          key: const PageStorageKey('home-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Padding(
                    padding: AppSpacing.page,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HomeGreeting(),
                        const SizedBox(height: AppSpacing.lg),
                        AppSearchField(
                          hintText: 'Tìm quán trong bán kính 5 km',
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          manual == null
                              ? 'Tâm tìm kiếm: vị trí thiết bị'
                              : 'Tâm tìm kiếm: ${manual.latitude.toStringAsFixed(4)}, ${manual.longitude.toStringAsFixed(4)}',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            TextButton.icon(
                              onPressed: () => ref
                                  .read(discoveryCenterProvider.notifier)
                                  .choose(phungKhoangCenter),
                              icon: const Icon(Icons.place_outlined),
                              label: const Text('Xem Chợ Phùng Khoang'),
                            ),
                            if (manual != null && location.point != null)
                              TextButton.icon(
                                onPressed: () => ref
                                    .read(discoveryCenterProvider.notifier)
                                    .useDeviceLocation(),
                                icon: const Icon(Icons.my_location),
                                label: const Text('Dùng vị trí thiết bị'),
                              ),
                          ],
                        ),
                        if (center != null) ...[
                          Text(
                            'Quán OpenStreetMap · Khoảng cách đường chim bay · Bán kính 5 km',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          ref
                              .watch(osmDataDateProvider)
                              .maybeWhen(
                                data: (date) => Text(
                                  'Dữ liệu cập nhật ${date.day}/${date.month}/${date.year} · © OpenStreetMap contributors',
                                  style: context.textStyles.labelSmall
                                      ?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                ),
                                orElse: () => const SizedBox.shrink(),
                              ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ...nearby.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              loading: () => [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: AppSpacing.page,
                    child: AppRestaurantSkeleton(),
                  ),
                ),
              ],
              error: (error, _) => [
                SliverToBoxAdapter(
                  child: AppMessage(
                    message: AppErrorMessage.from(
                      error,
                      fallback: 'Không tải được quán trong khu vực này.',
                    ),
                    onRetry: () => ref.invalidate(homeNearbyPlacesProvider),
                  ),
                ),
              ],
              data: (places) => places == null
                  ? [
                      SliverToBoxAdapter(
                        child: AppMessage(
                          message: location.locating
                              ? 'Đang lấy vị trí thiết bị…'
                              : 'Chọn Chợ Phùng Khoang hoặc cấp quyền vị trí để tìm quán.',
                        ),
                      ),
                    ]
                  : _placeSlivers(places, center!),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _placeSlivers(List<Place> places, GeoPoint center) {
    final categories = places.map((place) => place.category).toSet().toList()
      ..sort();
    final matches = filterPlaces(places, _query, _category);
    return [
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.margin,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
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
                            selected: _category == category,
                            onSelected: (selected) => setState(
                              () => _category = selected ? category : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSectionHeader(
                    title: 'Quán quanh khu vực này',
                    subtitle: '${matches.length} quán phù hợp trong 5 km',
                    actionLabel: 'Mở bản đồ',
                    onAction: () => context.go(AppRoute.map.path),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
      if (matches.isEmpty)
        const SliverToBoxAdapter(
          child: AppMessage(message: 'Không tìm thấy quán phù hợp.'),
        )
      else
        SliverList.builder(
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final place = matches[index];
            final distance = center.distanceTo(
              GeoPoint(place.latitude, place.longitude),
            );
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.margin,
                  ),
                  child: AppRestaurantCard(
                    name: place.name,
                    category: place.category,
                    address: place.address.isEmpty ? null : place.address,
                    distanceLabel:
                        '${AppFormatters.distance(distance)} · đường chim bay',
                    compact: true,
                    showReviewSummary: false,
                    onTap: () => context.go(
                      AppRoute.map.location(query: {'restaurantId': place.id}),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
    ];
  }
}
