# T15 — Favorites

Màn `/favorites` được đối chiếu với Stitch screen `09 - Favorites` (`e33fd35596124197a819fe91c542cf8f`). UI giữ app shell hiện có: header Food Review, tìm kiếm và sắp xếp, chip danh mục, thẻ tổng quan, danh sách `PlaceCard` dùng chung và bottom navigation.

## Triển khai

- `FavoritesScreen` xử lý SafeArea, cuộn, tìm theo tên/món, lọc danh mục và sắp xếp theo gần đây, điểm đánh giá hoặc tên.
- `favoriteIdsProvider` đọc danh sách theo phiên đăng nhập, cập nhật lạc quan khi lưu/bỏ lưu và hoàn tác khi repository trả lỗi.
- `FavoriteRepository` dùng stream `watchPlaceIds(userId)` và thao tác bất đồng bộ `setFavorite(...)`; các card Home, Search, Detail và Favorites dùng chung notifier.
- Guest được đưa qua `AuthGate`; trạng thái loading/error có retry; danh sách rỗng và kết quả lọc rỗng có CTA phù hợp.

## Dữ liệu và giới hạn

Hiện `MemoryFavoriteRepository` là adapter demo trong RAM, nên dữ liệu mẫu mất khi app khởi động lại và chưa ghi Firestore. Khi tích hợp backend, giữ nguyên contract domain và thay implementation/provider ở tầng data.
