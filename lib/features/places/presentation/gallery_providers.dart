import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../reviews/presentation/review_providers.dart';
import '../data/place_gallery_repository.dart';
import '../domain/gallery.dart';
import '../domain/gallery_repository.dart';
import 'place_providers.dart';

final galleryRepositoryProvider = Provider<GalleryRepository>(
  (ref) => PlaceGalleryRepository(ref.watch(reviewRepositoryProvider)),
);
final galleryProvider = FutureProvider.autoDispose
    .family<GalleryCollection, GalleryRequest>((ref, request) async {
      final repository = ref.watch(galleryRepositoryProvider);
      final place = await ref.watch(placeProvider(request.placeId).future);
      if (place == null) throw const AppException('Không tìm thấy quán.');
      return repository.getPhotos(place, request);
    }, retry: (_, _) => null);
