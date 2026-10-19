import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../shared/widgets/app_review_card.dart';
import '../domain/review.dart';

/// Shared route/data adapter for the detail preview and full review feed.
class RestaurantReviewCard extends StatelessWidget {
  const RestaurantReviewCard({
    super.key,
    required this.review,
    this.expandedImages = false,
  });
  final Review review;
  final bool expandedImages;
  @override
  Widget build(BuildContext context) {
    final date = review.createdAt.toLocal();
    return AppReviewCard(
      reviewerName: review.authorName,
      content: review.content,
      rating: review.rating.toDouble(),
      timeLabel: !expandedImages && review.isDemo
          ? 'Đánh giá minh họa'
          : '${date.day}/${date.month}/${date.year}${review.isDemo ? " · Minh họa" : ""}',
      dishes: expandedImages ? review.dishes : const [],
      imageUrls: review.imageUrls,
      expandedImages: expandedImages,
      onReviewerTap: () => context.push(
        AppRoute.reviewer.location(parameters: {'userId': review.userId}),
      ),
      onMore: () => context.push(
        AppRoute.createReport.location(
          query: {
            'targetType': 'review',
            'restaurantId': review.placeId,
            'reviewId': review.id,
          },
        ),
      ),
      onImageTap: (index) => context.push(
        AppRoute.gallery.location(
          parameters: {'restaurantId': review.placeId},
          query: {'index': '$index', 'source': 'review', 'reviewId': review.id},
        ),
      ),
    );
  }
}
