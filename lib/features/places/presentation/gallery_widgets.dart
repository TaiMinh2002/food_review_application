import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';
import '../domain/gallery.dart';

class GalleryImage extends StatefulWidget {
  const GalleryImage({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
    this.compact = false,
  });
  final GalleryPhoto photo;
  final BoxFit fit;
  final bool compact;
  @override
  State<GalleryImage> createState() => _GalleryImageState();
}

class _GalleryImageState extends State<GalleryImage> {
  int _attempt = 0;
  @override
  Widget build(BuildContext context) => AppImage(
    key: ValueKey((widget.photo.url, _attempt)),
    url: widget.photo.url,
    fit: widget.fit,
    semanticLabel: widget.photo.title,
    loadingFallback: const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(),
      ),
    ),
    fallback: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.compact)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Không tải được ảnh', textAlign: TextAlign.center),
            ),
          IconButton(
            tooltip: 'Thử tải lại ảnh',
            onPressed: () => setState(() => _attempt++),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    ),
  );
}

class GalleryFeatured extends StatelessWidget {
  const GalleryFeatured({
    super.key,
    required this.photo,
    required this.count,
    required this.onTap,
  });
  final GalleryPhoto photo;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.inputBorder),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Semantics(
              button: true,
              label: 'Mở ảnh nổi bật',
              child: InkWell(
                onTap: onTap,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: GalleryImage(photo: photo),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IgnorePointer(
                child: AppBadge(
                  label: photo.isDemo ? 'Ảnh minh họa' : 'Ảnh quán',
                  tone: AppBadgeTone.primary,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Tooltip(
                message: 'Lưu ảnh chưa được hỗ trợ',
                child: IconButton.filledTonal(
                  style: ButtonStyle(
                    shape: const WidgetStatePropertyAll(CircleBorder()),
                    backgroundColor: WidgetStatePropertyAll(
                      context.colors.surface,
                    ),
                    foregroundColor: WidgetStatePropertyAll(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  onPressed: null,
                  icon: Icon(Icons.favorite_border),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.scrim.withValues(alpha: .7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        size: 16,
                        color: context.semanticColors.onImage,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '1 / $count',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.semanticColors.onImage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.ramen_dining, color: context.colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleMedium,
                      ),
                      if (photo.author != null)
                        Text(
                          photo.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.labelSmall,
                        ),
                    ],
                  ),
                ),
                const Tooltip(
                  message: 'Xem ảnh nổi bật',
                  child: Icon(Icons.arrow_forward, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class GalleryTile extends StatelessWidget {
  const GalleryTile({super.key, required this.photo, required this.onTap});
  final GalleryPhoto photo;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.inputBorder),
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: GalleryImage(photo: photo, compact: true),
              ),
              Positioned(
                top: 6,
                left: 6,
                right: 6,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.scrim.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      photo.category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.semanticColors.onImage,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 18,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    photo.author ?? 'Chưa có tác giả',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelSmall,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.zoom_in, size: 16, color: context.colors.primary),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class GalleryContribution extends StatelessWidget {
  const GalleryContribution({super.key, required this.onUpload});
  final VoidCallback onUpload;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLow,
      borderRadius: AppRadii.inputBorder,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final prompt = Row(
          children: [
            Icon(Icons.add_a_photo_outlined, color: context.colors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn có ảnh đẹp tại quán?',
                    style: context.textStyles.titleMedium,
                  ),
                  Text(
                    'Chia sẻ trải nghiệm cùng mọi người',
                    style: context.textStyles.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        );
        final action = AppButton(
          label: 'Đăng ảnh',
          icon: Icons.upload,
          onPressed: onUpload,
        );
        return constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 19
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [prompt, const SizedBox(height: 12), action],
              )
            : Row(
                children: [
                  Expanded(child: prompt),
                  const SizedBox(width: 12),
                  action,
                ],
              );
      },
    ),
  );
}
