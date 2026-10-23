import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/cloudinary_review_photo_uploader.dart';
import '../data/demo_review_repository.dart';
import '../data/firestore_review_repository.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';

final reviewPhotoUploaderProvider = Provider<CloudinaryReviewPhotoUploader>((
  ref,
) {
  return CloudinaryReviewPhotoUploader();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    final repository = DemoReviewRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  final repository = FirestoreReviewRepository(FirebaseFirestore.instance);
  ref.onDispose(repository.dispose);
  return repository;
});

/// Only a bounded preview; the full list/pagination belongs to T09a.
final reviewPreviewProvider = StreamProvider.autoDispose
    .family<List<Review>, String>(
      (ref, placeId) =>
          ref.watch(reviewRepositoryProvider).watchForPlace(placeId, limit: 2),
      retry: (retryCount, error) => null,
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
