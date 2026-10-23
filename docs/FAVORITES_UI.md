# T15 — Favorites

Màn `/favorites` được đối chiếu với Stitch screen `09 - Favorites` (`e33fd35596124197a819fe91c542cf8f`). UI giữ app shell hiện có: header Food Review, tìm kiếm và sắp xếp, chip danh mục, thẻ tổng quan, danh sách `PlaceCard` dùng chung và bottom navigation.

## Triển khai

- `FavoritesScreen` xử lý SafeArea, cuộn, tìm theo tên/món, lọc danh mục và sắp xếp theo gần đây, điểm đánh giá hoặc tên.
- `favoriteIdsProvider` đọc danh sách theo phiên đăng nhập, cập nhật lạc quan khi lưu/bỏ lưu và hoàn tác khi repository trả lỗi.
- `FavoriteRepository` dùng stream `watchPlaceIds(userId)` và thao tác bất đồng bộ `setFavorite(...)`; các card Home, Search, Detail và Favorites dùng chung notifier.
- Guest được đưa qua `AuthGate`; trạng thái loading/error có retry; danh sách rỗng và kết quả lọc rỗng có CTA phù hợp.

## Dữ liệu và tích hợp Firestore

- Đã tích hợp `FirestoreFavoriteRepository` lưu trữ vĩnh viễn trên Cloud Firestore theo đường dẫn `users/{uid}/favorites/{placeKey}` (0-cost Spark).
- `favoritePlacesProvider` giải quyết thông tin quán theo ID cả từ nguồn OSM thật (`osm_node_*`, `osm_way_*`) lẫn dữ liệu demo một cách mượt mà.
- Tự động fallback sang `MemoryFavoriteRepository` trong môi trường test/chưa kết nối Firebase để duy trì 100% tính độc lập khi kiểm thử.
