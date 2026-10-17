import '../domain/place.dart';
import 'demo_place_repository.dart';

/// Opt-in fixtures for UI development. The default demo remains unchanged.
/// Image URLs are illustrative references from Stitch Home, not venue evidence.
abstract final class DemoPlaceFixtures {
  static const empty = <Place>[];
  static const withoutImages = DemoPlaceRepository.places;

  static final withImages = _withImageUrls(_stitchImages);
  static final brokenImages = _withImageUrls(
    List.filled(withoutImages.length, 'https://images.invalid/food-demo.jpg'),
  );

  static List<Place> _withImageUrls(List<String> urls) => List.unmodifiable([
    for (var i = 0; i < withoutImages.length; i++)
      Place(
        id: withoutImages[i].id,
        name: withoutImages[i].name,
        description: withoutImages[i].description,
        address: withoutImages[i].address,
        category: withoutImages[i].category,
        latitude: withoutImages[i].latitude,
        longitude: withoutImages[i].longitude,
        imageUrls: List.unmodifiable([urls[i]]),
        averageRating: withoutImages[i].averageRating,
        reviewCount: withoutImages[i].reviewCount,
      ),
  ]);

  static const _stitchImages = [
    'https://lh3.googleusercontent.com/aida/AEtjO1W7UzRUrC7qibx0Pb7z-HhoP9RrykMwTPxioiZVppjwTQr0xJLBCFwqcYD2nN0yXr7eAxherR8TTJoHGmJs9YkrJyPb4RYypEXKXlgljpjDg3ncU8B3I2hyXVwQzf3g5OEZbbJeOeA3tCm5tbU8METs7B5CQotKz-7W486J96xsx8yDJXQZP8cY3kE1_a0EWjJ8Ex3iBq260w5TIcb81ultcfN3iUs8pVBio_QHSuJTijU3EL9zcKkgckvP',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuAZ15lxsMsiC8YQ-iPgeLoXr-NRoIVUsIVgcKM-TRSOigNNts74SDReMY0yfDo71SftF52wFCyrDPYLYs-_0vuc1LXXTEJwOhlM7OXWhMBsiXRMD8OXI8ODgLjH24wf0A2UXuVe8QSj7PO9s2UXBTX_b-1cOIifEZG3BFKe2nMTFtbcDZ7y9pFFFHE-gL8E3aov-bevn_qnwCO2t5iNl0jOGSFFsOPBYJe1XbAGa5YglaAkIvsRcNQWZw',
    'https://lh3.googleusercontent.com/aida/AEtjO1WB4BBXJ5glc_GnwSOVBcjA44Z5F58bbxzAqwFlOk05zieqD9xDJpbsVpwjT-psfhkvawKJ4PJRhLmFf2QlwOSBYGJpSHH0K5jyvohSiAEFJsVo95dMHHWF_h6oeS5RNpMwgtaQRjeAXimN0TUAwUazfHiLuKslz9ljORNzrPyd5uAzgLIhWmDJEmli6OD8U5S_gineWQnbVL8YOsk6g0udpsJmaKtyplTaNbSlwyc4xxrumDkeTobdt6o',
  ];
}
