import 'review.dart';

abstract interface class ReviewRepository {
  Stream<List<Review>> watchForPlace(String placeId, {int limit = 20});
  Future<void> create(Review review);
}
