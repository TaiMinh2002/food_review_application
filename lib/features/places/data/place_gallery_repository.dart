import '../../../core/errors/app_exception.dart';
import '../../reviews/domain/review_repository.dart';
import '../domain/gallery.dart';
import '../domain/gallery_repository.dart';
import '../domain/place.dart';

class PlaceGalleryRepository implements GalleryRepository {
  PlaceGalleryRepository(this.reviews);
  final ReviewRepository reviews;
  @override
  Future<GalleryCollection> getPhotos(
    Place place,
    GalleryRequest request,
  ) async {
    if (place.id != request.placeId) {
      throw const AppException('Ảnh không thuộc quán đã chọn.');
    }
    if (request.fromReview) {
      final id = request.reviewId;
      if (id == null || id.trim().isEmpty) {
        throw const AppException('Đường dẫn thiếu mã đánh giá.');
      }
      if (reviews is! ReviewMediaRepository) {
        throw const AppException(
          'Nguồn dữ liệu chưa hỗ trợ ảnh của đánh giá này.',
        );
      }
      final review = await (reviews as ReviewMediaRepository).getReview(
        place.id,
        id,
      );
      if (review == null || review.placeId != place.id || review.id != id) {
        throw const AppException('Không tìm thấy đánh giá của quán này.');
      }
      // Do not deduplicate: index refers to the original review's photo order.
      return GalleryCollection([
        for (var i = 0; i < review.imageUrls.length; i++)
          GalleryPhoto(
            url: review.imageUrls[i],
            title: 'Ảnh đánh giá ${i + 1}',
            author: review.authorName,
            isDemo: review.isDemo,
          ),
      ]);
    }
    final metadata = {
      for (final photo in place.galleryPhotos) photo.url: photo,
    };
    // Preserve canonical detail indices (including duplicates/empty URLs).
    final photos = <GalleryPhoto>[];
    for (var i = 0; i < place.imageUrls.length; i++) {
      final photo = metadata[place.imageUrls[i]];
      photos.add(
        GalleryPhoto(
          url: place.imageUrls[i],
          title: photo?.title ?? 'Ảnh quán ${i + 1}',
          author: photo?.author,
          category: photo?.category ?? PhotoCategory.other,
          isDemo: place.isDemo || (photo?.isDemo ?? false),
        ),
      );
    }
    final known = place.imageUrls.toSet();
    for (final photo in place.galleryPhotos) {
      if (known.add(photo.url)) photos.add(photo);
    }
    return GalleryCollection(photos);
  }
}
