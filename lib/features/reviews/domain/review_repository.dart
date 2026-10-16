import 'review.dart';

abstract interface class ReviewRepository {
  Stream<List<Review>> watchForPlace(String placeId);
  Future<void> create(Review review);
}
