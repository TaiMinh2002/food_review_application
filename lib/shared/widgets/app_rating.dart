import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppRating extends StatelessWidget {
  const AppRating({
    super.key,
    required this.value,
    this.count,
    this.showStars = false,
  });
  final double value;
  final int? count;
  final bool showStars;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${value.toStringAsFixed(1)} trên 5 sao${count == null ? "" : ", $count đánh giá"}',
    child: ExcludeSemantics(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          if (showStars)
            for (var i = 1; i <= 5; i++)
              Icon(
                value >= i
                    ? Icons.star_rounded
                    : value >= i - .5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
                size: 18,
                color: context.semanticColors.rating,
              )
          else
            Icon(
              Icons.star_rounded,
              size: 18,
              color: context.semanticColors.rating,
            ),
          Text(value.toStringAsFixed(1), style: context.textStyles.labelMedium),
          if (count != null)
            Text(
              '($count)',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    ),
  );
}

class AppRatingInput extends StatelessWidget {
  const AppRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final int value;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    children: [
      for (var star = 1; star <= 5; star++)
        Semantics(
          selected: star <= value,
          child: IconButton(
            tooltip: '$star sao',
            onPressed: onChanged == null ? null : () => onChanged!(star),
            icon: Icon(
              star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: context.semanticColors.rating,
              size: 28,
            ),
          ),
        ),
    ],
  );
}

class AppRatingSummary extends StatelessWidget {
  const AppRatingSummary({
    super.key,
    required this.value,
    required this.count,
    this.title = 'Đánh giá từ cộng đồng',
  });
  final double value;
  final int count;
  final String title;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                value.toStringAsFixed(1),
                style: context.textStyles.headlineLarge,
              ),
              AppRating(value: value, showStars: true),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleMedium),
                Text(
                  'Dựa trên $count lượt đánh giá',
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
