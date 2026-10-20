import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';
import '../domain/collection_editor.dart';

class CollectionCoverPreview extends StatelessWidget {
  const CollectionCoverPreview({super.key, this.first});
  final CollectionPlace? first;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadii.inputBorder,
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: AppRadii.inputBorder,
          child: SizedBox.square(
            dimension: 76,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  url: first?.imageUrl,
                  fallback: Icon(
                    Icons.collections_bookmark_outlined,
                    color: context.colors.primary,
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.xs,
                  left: AppSpacing.xs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: AppRadii.inputBorder,
                    ),
                    child: Text(
                      'Bìa',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ảnh bìa bộ sưu tập', style: context.textStyles.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ảnh bìa lấy tự động từ địa điểm đầu tiên trong danh sách bên dưới.',
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CollectionPlaceRow extends StatelessWidget {
  const CollectionPlaceRow({
    super.key,
    required this.place,
    required this.first,
    this.onRemove,
  });
  final CollectionPlace place;
  final bool first;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Material(
      color: context.colors.surface,
      borderRadius: AppRadii.inputBorder,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.small),
              child: AppImage(url: place.imageUrl, width: 52, height: 52),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (first)
                    Text(
                      'Ảnh bìa',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  Text(place.name, style: context.textStyles.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    place.subtitle,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: place.available
                          ? context.colors.onSurfaceVariant
                          : context.colors.error,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Bỏ ${place.name} khỏi bộ sưu tập',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
      ),
    ),
  );
}
