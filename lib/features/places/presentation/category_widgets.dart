import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';
import '../domain/place_category.dart';

class CategoryHero extends StatelessWidget {
  const CategoryHero({
    super.key,
    required this.category,
    required this.countLabel,
  });
  final PlaceCategory category;
  final String countLabel;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: AppRadii.inputBorder,
    child: Stack(
      children: [
        Positioned.fill(
          child: AppImage(
            url: switch (category.id) {
              'ca-phe' => 'assets/images/demo/coffee.jpg',
              'banh-mi' || 'an-nhanh' => 'assets/images/demo/banh_mi.jpg',
              _ => 'assets/images/demo/pho.jpg',
            },
            semanticLabel: 'Ảnh món ăn minh họa',
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.colors.scrim.withValues(alpha: .15),
                  context.colors.scrim.withValues(alpha: .9),
                ],
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 126),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final titles = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      style: context.textStyles.headlineMedium?.copyWith(
                        color: context.semanticColors.onImage,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Khám phá những quán ${category.label.toLowerCase()}',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.semanticColors.onImage,
                      ),
                    ),
                  ],
                );
                final badge = AppBadge(
                  label: countLabel,
                  tone: AppBadgeTone.primary,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        'Ảnh minh họa',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.semanticColors.onImage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (constraints.maxWidth >= 300 &&
                        MediaQuery.textScalerOf(context).scale(14) <= 19)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: titles),
                          const SizedBox(width: 8),
                          badge,
                        ],
                      )
                    else ...[
                      titles,
                      const SizedBox(height: 8),
                      badge,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
