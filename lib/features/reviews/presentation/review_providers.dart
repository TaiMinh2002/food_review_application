import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
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

typedef ReviewLookup = ({String placeId, String reviewId});

final reviewForEditProvider = FutureProvider.autoDispose
    .family<Review?, ReviewLookup>((ref, lookup) async {
      final repository = ref.watch(reviewRepositoryProvider);
      if (repository is! ReviewManagementRepository) {
        return null;
      }
      final management = repository as ReviewManagementRepository;
      final review = await management.getReview(
        lookup.placeId,
        lookup.reviewId,
      );
      final user = ref.read(authSessionProvider).asData?.value;
      return user != null && review?.userId == user.id ? review : null;
    });

final myReviewsProvider = StreamProvider.autoDispose<List<Review>>((ref) {
  final user = ref.watch(authSessionProvider).asData?.value;
  if (user == null) return Stream.value(const []);
  final repository = ref.watch(reviewRepositoryProvider);
  if (repository is! ReviewManagementRepository) return Stream.value(const []);
  final management = repository as ReviewManagementRepository;
  return management.watchForUser(user.id);
});
