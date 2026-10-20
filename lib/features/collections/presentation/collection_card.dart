import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';
import '../domain/collection_repository.dart';

enum CollectionAction { edit, delete }

class CollectionCard extends StatelessWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    required this.onOpen,
    required this.onAction,
    required this.busy,
  });
  final PlaceCollection collection;
  final VoidCallback onOpen;
  final ValueChanged<CollectionAction> onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    borderRadius: AppRadii.inputBorder,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: busy ? null : onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRect(
                  child: Transform.scale(
                    scale: 1.12,
                    child: AppImage(url: collection.coverUrl),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: PopupMenuButton<CollectionAction>(
                  tooltip: 'Tùy chọn ${collection.name}',
                  enabled: !busy,
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.surface.withValues(
                      alpha: .95,
                    ),
                    foregroundColor: context.colors.onSurface,
                    minimumSize: const Size(44, 44),
                    shape: const CircleBorder(),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: onAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: CollectionAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Chỉnh sửa bộ sưu tập'),
                      ),
                    ),
                    const PopupMenuItem<CollectionAction>(
                      enabled: false,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.share_outlined),
                        title: Text('Chia sẻ với bạn bè'),
                        subtitle: Text('Chưa hỗ trợ • Bộ sưu tập riêng tư'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: CollectionAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: context.colors.error,
                        ),
                        title: Text(
                          'Xóa bộ sưu tập',
                          style: TextStyle(color: context.colors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collection.name, style: context.textStyles.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  collection.description,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 16,
                      color: context.colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${collection.placeCount} địa điểm',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
