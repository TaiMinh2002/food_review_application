import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/place.dart';

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.location_on, size: 15, color: context.colors.secondary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'TP. Hồ Chí Minh · Vị trí minh họa',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.secondary,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text('Hôm nay ăn gì?', style: context.textStyles.headlineLarge),
      Text(
        'Khám phá hương vị và những quán ngon quanh bạn',
        style: context.textStyles.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class HomeCommunityBanner extends StatelessWidget {
  const HomeCommunityBanner({super.key, required this.onWriteReview});
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.primary,
      borderRadius: AppRadii.cardBorder,
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CỘNG ĐỒNG SÀNH ĂN',
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Bạn vừa thưởng thức món ngon?',
                style: context.textStyles.headlineSmall?.copyWith(
                  color: context.colors.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Chia sẻ cảm nhận chân thật của bạn.',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onPrimary,
                ),
              ),
            ],
          );
          final button = FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.surface,
              foregroundColor: context.colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onPressed: onWriteReview,
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Viết review'),
          );
          if (constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(14) > 18) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 12), button],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    ),
  );
}

Future<void> showHomeReviewPicker(
  BuildContext context,
  List<Place> places,
) async {
  final id = await showAppBottomSheet<String>(
    context,
    title: 'Bạn muốn đánh giá quán nào?',
    builder: (context) => Column(
      children: [
        Text(
          'Chọn quán trước khi viết review. Tính năng đăng đánh giá đang được phát triển.',
          style: context.textStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final place in places)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restaurant_outlined),
            title: Text(place.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, place.id),
          ),
      ],
    ),
  );
  if (id != null && context.mounted) {
    context.push(
      AppRoute.createReview.location(parameters: {'restaurantId': id}),
    );
  }
}
