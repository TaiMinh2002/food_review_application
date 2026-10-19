import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_review_repository.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => DemoReviewRepository(),
);

/// Only a bounded preview; the full list/pagination belongs to T09a.
final reviewPreviewProvider = StreamProvider.autoDispose
    .family<List<Review>, String>(
      (ref, placeId) =>
          ref.watch(reviewRepositoryProvider).watchForPlace(placeId, limit: 2),
      retry: (count, error) => null,
    );
