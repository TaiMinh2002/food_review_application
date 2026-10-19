import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_avatar.dart';
import 'app_chip.dart';
import 'app_image.dart';
import 'app_rating.dart';

class AppReviewCard extends StatelessWidget {
  const AppReviewCard({
    super.key,
    required this.reviewerName,
    required this.content,
    required this.rating,
    required this.timeLabel,
    this.avatarUrl,
    this.verified = false,
    this.reviewerBadge,
    this.dishes = const [],
    this.imageUrls = const [],
    this.helpfulCount = 0,
    this.replyCount = 0,
    this.isHelpful = false,
    this.onHelpful,
    this.onReplies,
    this.onMore,
    this.onImageTap,
    this.onReviewerTap,
  });
  final String reviewerName, content, timeLabel;
  final String? avatarUrl, reviewerBadge;
  final double rating;
  final bool verified, isHelpful;
  final List<String> dishes, imageUrls;
  final int helpfulCount, replyCount;
  final VoidCallback? onHelpful, onReplies, onMore, onReviewerTap;
  final ValueChanged<int>? onImageTap;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onReviewerTap,
                child: AppAvatar(name: reviewerName, imageUrl: avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reviewerName, style: context.textStyles.titleMedium),
                    Text(
                      timeLabel,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onMore != null)
                IconButton(
                  tooltip: 'Tùy chọn nhận xét',
                  onPressed: onMore,
                  icon: const Icon(Icons.more_vert),
                ),
            ],
          ),
          if (verified || reviewerBadge != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (verified)
                    const AppBadge(
                      label: 'Đã trải nghiệm',
                      icon: Icons.verified_outlined,
                      tone: AppBadgeTone.primary,
                    ),
                  if (reviewerBadge != null)
                    AppBadge(label: reviewerBadge!, tone: AppBadgeTone.accent),
                ],
              ),
            ),
          const SizedBox(height: 12),
          AppRating(value: rating, showStars: true, showValue: false),
          const SizedBox(height: 8),
          Text(content, style: context.textStyles.bodyMedium),
          if (dishes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final dish in dishes) AppBadge(label: dish)],
              ),
            ),
          if (imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => Semantics(
                    label: 'Ảnh đánh giá ${index + 1}',
                    button: onImageTap != null,
                    child: InkWell(
                      onTap: onImageTap == null
                          ? null
                          : () => onImageTap!(index),
                      child: ClipRRect(
                        borderRadius: AppRadii.inputBorder,
                        child: AppImage(
                          url: imageUrls[index],
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (onHelpful != null || onReplies != null) ...[
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (onHelpful != null)
                  TextButton.icon(
                    onPressed: onHelpful,
                    icon: Icon(
                      isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 16,
                    ),
                    label: Text('Hữu ích ($helpfulCount)'),
                  ),
                if (onReplies != null)
                  TextButton.icon(
                    onPressed: onReplies,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: Text('$replyCount phản hồi'),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
