import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_image.dart';

enum AppAvatarSize {
  small(28),
  medium(40),
  large(56);

  const AppAvatarSize(this.diameter);
  final double diameter;
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = AppAvatarSize.medium,
    this.isOnline = false,
  });
  final String name;
  final String? imageUrl;
  final AppAvatarSize size;
  final bool isOnline;
  @override
  Widget build(BuildContext context) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? '?'
        : [
            parts.first,
            if (parts.length > 1) parts.last,
          ].map((p) => p.characters.first).join().toUpperCase();
    final fallback = Center(
      child: Text(
        initials,
        style: context.textStyles.labelLarge?.copyWith(
          color: context.colors.onPrimaryContainer,
          fontSize: size.diameter * .34,
        ),
      ),
    );
    return Semantics(
      label: '$name${isOnline ? ", đang hoạt động" : ""}',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size.diameter,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipOval(
                  child: ColoredBox(
                    color: context.colors.primaryContainer,
                    child: imageUrl == null
                        ? fallback
                        : AppImage(url: imageUrl, fallback: fallback),
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: size.diameter * .25,
                    height: size.diameter * .25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.semanticColors.success,
                      border: Border.all(
                        color: context.colors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
