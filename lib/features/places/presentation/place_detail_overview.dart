import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/place.dart';

String placePriceLabel(Place place) =>
    place.minPrice != null && place.maxPrice != null
    ? AppFormatters.priceRange(place.minPrice!, place.maxPrice!)
    : 'Chưa cập nhật giá';

class PlaceDetailOverview extends StatelessWidget {
  const PlaceDetailOverview({
    super.key,
    required this.place,
    required this.photoIndex,
    required this.onPhotoChanged,
    required this.onGallery,
    required this.onMap,
    required this.quickActions,
  });
  final Place place;
  final int photoIndex;
  final ValueChanged<int> onPhotoChanged;
  final VoidCallback onGallery, onMap;
  final Widget quickActions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final heroHeight = math.min(constraints.maxWidth * .82, 360.0);
      return Stack(
        children: [
          SizedBox(
            height: heroHeight,
            child: Stack(
              children: [
                if (place.imageUrls.isEmpty)
                  const Positioned.fill(child: AppImage())
                else
                  Positioned.fill(
                    child: PageView.builder(
                      key: PageStorageKey('detail-photos-${place.id}'),
                      itemCount: place.imageUrls.length,
                      onPageChanged: onPhotoChanged,
                      itemBuilder: (context, index) => Semantics(
                        label: 'Mở ảnh ${index + 1} của ${place.name}',
                        button: true,
                        child: InkWell(
                          onTap: onGallery,
                          child: AppImage(
                            url: place.imageUrls[index],
                            semanticLabel: place.name,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (place.isDemo)
                  const Positioned(
                    left: 20,
                    bottom: 32,
                    child: AppBadge(
                      label: 'Ảnh minh họa',
                      tone: AppBadgeTone.accent,
                    ),
                  ),
                if (place.imageUrls.isNotEmpty)
                  Positioned(
                    right: 20,
                    bottom: 28,
                    child: FilledButton.tonalIcon(
                      onPressed: onGallery,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colors.inverseSurface,
                        foregroundColor: context.colors.onInverseSurface,
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.photo_camera_outlined, size: 16),
                      label: Text(
                        '${photoIndex + 1}/${place.imageUrls.length} ảnh',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onInverseSurface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: heroHeight - 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.sheet),
                ),
              ),
              child: Padding(
                padding: AppSpacing.page,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.outlineVariant,
                          borderRadius: AppRadii.inputBorder,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      place.category,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(place.name, style: context.textStyles.headlineLarge),
                    const SizedBox(height: AppSpacing.sm),
                    if (place.reviewCount > 0)
                      AppRating(
                        value: place.averageRating,
                        count: place.reviewCount,
                      )
                    else
                      Text(
                        'Chưa có đánh giá',
                        style: context.textStyles.bodyMedium,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 16,
                          color: context.colors.primary,
                        ),
                        Text(
                          place.openingHours == null
                              ? 'Chưa cập nhật giờ phục vụ'
                              : 'Giờ phục vụ: ${place.openingHours}',
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                    if (place.isDemo)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Bản demo · Ảnh, giá, giờ phục vụ, thực đơn và đánh giá minh họa.',
                          style: context.textStyles.labelSmall?.copyWith(
                            color: context.colors.secondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoPanel(
                      icon: Icons.payments_outlined,
                      title: 'Khoảng giá ước tính',
                      child: Text(
                        placePriceLabel(place),
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InfoPanel(
                      icon: Icons.location_on_outlined,
                      title: place.address,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chưa sử dụng vị trí của bạn',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onMap,
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text('Xem bản đồ'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    quickActions,
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLow,
      borderRadius: AppRadii.inputBorder,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: context.colors.primaryContainer,
          child: Icon(icon, size: 22, color: context.colors.onPrimaryContainer),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textStyles.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              child,
            ],
          ),
        ),
      ],
    ),
  );
}

class PlaceDetailQuickActions extends StatelessWidget {
  const PlaceDetailQuickActions({
    super.key,
    required this.favorite,
    required this.onFavorite,
    required this.onShare,
    required this.onMenu,
    required this.onContact,
  });
  final bool favorite;
  final VoidCallback onFavorite, onShare, onMenu, onContact;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(12) > 16
          ? 2
          : 4;
      final actions = [
        (Icons.call_outlined, 'Gọi điện', onContact),
        (
          favorite ? Icons.favorite : Icons.favorite_border,
          favorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
          onFavorite,
        ),
        (Icons.share_outlined, 'Chia sẻ', onShare),
        (Icons.restaurant_menu, 'Thực đơn', onMenu),
      ];
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (icon, label, action) in actions)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 8) / columns,
              child: Material(
                color: context.colors.surfaceContainerLow,
                borderRadius: AppRadii.inputBorder,
                child: InkWell(
                  onTap: action,
                  borderRadius: AppRadii.inputBorder,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: context.colors.surface,
                          child: Icon(
                            icon,
                            color: context.colors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class PlaceDetailPriceBar extends StatelessWidget {
  const PlaceDetailPriceBar({
    super.key,
    required this.place,
    required this.onDirections,
  });
  final Place place;
  final VoidCallback onDirections;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
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
                final price = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khoảng giá', style: context.textStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      placePriceLabel(place),
                      style: context.textStyles.titleMedium?.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                );
                final button = AppButton(
                  label: 'Chỉ đường',
                  icon: Icons.directions_outlined,
                  onPressed: onDirections,
                );
                if (constraints.maxWidth < 320 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [price, const SizedBox(height: 8), button],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: price),
                    const SizedBox(width: 12),
                    Expanded(child: button),
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
