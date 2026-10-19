import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';

class LoginBrand extends StatelessWidget {
  const LoginBrand({
    super.key,
    this.title = 'Chào mừng trở lại!',
    this.description =
        'Đăng nhập để khám phá và lưu lại những quán ăn yêu thích.',
  });
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: AppRadii.cardBorder,
            ),
            child: Icon(
              Icons.restaurant,
              color: context.colors.onPrimary,
              size: 32,
            ),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: context.colors.secondaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.semanticColors.canvas,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.circle,
                  size: 7,
                  color: context.colors.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          Text('Food Review', style: context.textStyles.headlineSmall),
          const AppBadge(label: 'Ẩm Thực Việt', tone: AppBadgeTone.primary),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        title,
        textAlign: TextAlign.center,
        style: context.textStyles.headlineLarge,
      ),
      const SizedBox(height: 4),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Text(
          description,
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}

class LoginFoodHighlight extends StatelessWidget {
  const LoginFoodHighlight({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadii.cardBorder,
    ),
    child: Row(
      children: [
        const ClipRRect(
          borderRadius: AppRadii.inputBorder,
          child: AppImage(
            url: 'assets/images/demo/pho.jpg',
            width: 56,
            height: 56,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HƯƠNG VỊ HÀ NỘI & SÀI GÒN',
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
              Text(
                'Khám phá ẩm thực Việt',
                style: context.textStyles.labelMedium,
              ),
              Text(
                'Ảnh minh họa · Dữ liệu quán hiện là mẫu',
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

class LoginError extends StatelessWidget {
  const LoginError({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.errorContainer,
        borderRadius: AppRadii.inputBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: context.colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
