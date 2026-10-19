import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';
import '../domain/gallery.dart';
import 'gallery_widgets.dart';

Future<void> showGalleryViewer(
  BuildContext context, {
  required List<GalleryPhoto> photos,
  required int index,
  required ValueChanged<GalleryPhoto> onShare,
}) async {
  if (photos.isEmpty) return;
  await showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (_) => _GalleryViewer(
      photos: photos,
      index: index.clamp(0, photos.length - 1),
      onShare: onShare,
    ),
  );
}

class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({
    required this.photos,
    required this.index,
    required this.onShare,
  });
  final List<GalleryPhoto> photos;
  final int index;
  final ValueChanged<GalleryPhoto> onShare;
  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final _controller = PageController(initialPage: widget.index);
  late int _index = widget.index;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _page(int index) => _controller.animateToPage(
    index,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );
  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    final foreground = context.semanticColors.onImage;
    return Dialog.fullscreen(
      backgroundColor: context.colors.scrim,
      child: Theme(
        data: Theme.of(context)
            .copyWith(iconTheme: IconThemeData(color: foreground)),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.photo_library_outlined, color: foreground),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_index + 1} / ${widget.photos.length}',
                        key: const ValueKey('gallery-counter'),
                        style: context.textStyles.labelMedium?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng ảnh',
                      color: foreground,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  key: const ValueKey('gallery-pages'),
                  controller: _controller,
                  itemCount: widget.photos.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, index) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: InteractiveViewer(
                      key: ValueKey('zoom-$index'),
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: SizedBox.expand(
                          child: GalleryImage(
                            photo: widget.photos[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      photo.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                    if (photo.author != null)
                      Text(
                        '${photo.author}${photo.isDemo ? ' · Minh họa' : ''}',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Ảnh trước',
                          color: foreground,
                          onPressed: _index > 0
                              ? () => _page(_index - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          tooltip: 'Ảnh sau',
                          color: foreground,
                          onPressed: _index < widget.photos.length - 1
                              ? () => _page(_index + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Chia sẻ ảnh',
                          color: foreground,
                          onPressed: () => widget.onShare(photo),
                          icon: const Icon(Icons.share_outlined),
                        ),
                        Tooltip(
                          message: 'Lưu ảnh chưa được hỗ trợ',
                          child: IconButton(
                            tooltip: 'Lưu ảnh chưa được hỗ trợ',
                            disabledColor: foreground.withValues(alpha: .4),
                            onPressed: null,
                            icon: const Icon(Icons.favorite_border),
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
      ),
    );
  }
}
