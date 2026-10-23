import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design_system/design_system.dart';
import '../domain/place_category.dart';
import 'discovery_center.dart';
import 'map_controller.dart';
import 'user_location_controller.dart';

class CategoryHero extends StatelessWidget {
  const CategoryHero({
    super.key,
    required this.category,
    required this.countLabel,
  });
  final PlaceCategory category;
  final String countLabel;

  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.primaryContainer,
    child: Padding(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.category_outlined,
            color: context.colors.onPrimaryContainer,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            category.label,
            style: context.textStyles.headlineMedium?.copyWith(
              color: context.colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            countLabel,
            style: context.textStyles.titleSmall?.copyWith(
              color: context.colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Quán OpenStreetMap trong bán kính 5 km',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    ),
  );
}

class CategoryChoices extends StatelessWidget {
  const CategoryChoices({super.key, this.selectedId, required this.onSelected});
  final String? selectedId;
  final ValueChanged<PlaceCategory> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.xs,
    children: [
      for (final category in PlaceCategory.osmValues)
        AppChip(
          label: category.label,
          selected: selectedId == category.id,
          onSelected: (_) => onSelected(category),
        ),
    ],
  );
}

class CategoryDiscoveryStatus extends ConsumerWidget {
  const CategoryDiscoveryStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.watch(activeDiscoveryCenterProvider);
    final manual = ref.watch(discoveryCenterProvider);
    final location = ref.watch(userLocationControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          center == null
              ? 'Chọn khu vực để xem quán thật.'
              : 'Tâm ${manual == null ? 'GPS' : 'đã chọn'}: '
                    '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
          style: context.textStyles.bodySmall,
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
        ref
            .watch(osmDataDateProvider)
            .maybeWhen(
              data: (date) => Text(
                'Nguồn ${date.day}/${date.month}/${date.year} · © OpenStreetMap contributors',
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
      ],
    );
  }
}
