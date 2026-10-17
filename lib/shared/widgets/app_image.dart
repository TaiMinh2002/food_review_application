import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Stable geometry and a themed fallback for missing/broken network images.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    this.url,
    this.semanticLabel,
    this.fallback,
    this.width,
    this.height,
  });
  final String? url, semanticLabel;
  final Widget? fallback;
  final double? width, height;
  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: context.colors.surfaceContainerLow,
      child:
          fallback ??
          Center(
            child: Icon(
              Icons.restaurant_outlined,
              color: context.colors.onSurfaceVariant,
            ),
          ),
    );
    if (url == null || url!.isEmpty) {
      return SizedBox(width: width, height: height, child: placeholder);
    }
    return Image.network(
      url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      errorBuilder: (_, _, _) =>
          SizedBox(width: width, height: height, child: placeholder),
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : SizedBox(width: width, height: height, child: placeholder),
    );
  }
}
