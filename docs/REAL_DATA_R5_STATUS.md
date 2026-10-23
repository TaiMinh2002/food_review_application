# R5 — Favorites thật trên Firestore

Cập nhật 23/10/2026. Triển khai trên nhánh `feat/favorites`, rebase từ `origin/dev` sau khi merge R3 Settings.

## Đã nối và chuẩn hóa

1. **FirestoreFavoriteRepository (`lib/features/favorites/data/firestore_favorite_repository.dart`)**:
   - Lưu trữ danh sách yêu thích tại `users/{uid}/favorites/{placeKey}` với timestamp máy chủ `createdAt`.
   - Lắng nghe real-time snapshots qua `watchPlaceIds(userId)`.
   - Thao tác thêm (`doc.set`) và xóa (`doc.delete`) xử lý an toàn lỗi permission và network.
   - Khi Firebase chưa khởi tạo hoặc trong unit test không có backend, tự động fallback sang `MemoryFavoriteRepository`.

2. **favoritePlacesProvider (`lib/features/favorites/presentation/favorite_providers.dart`)**:
   - Thay vì lọc từ danh sách demo cứng, provider giải quyết thông tin quán theo tập ID yêu thích từ `osmRegionPlaceRepositoryProvider` (cho quán OSM) và `placeRepositoryProvider` (cho quán demo).
   - Quán ở xa ngoài phạm vi bán kính 5 km hiện tại vẫn hiển thị đầy đủ trong danh sách Yêu thích.

3. **FavoritesScreen (`lib/features/favorites/presentation/favorites_screen.dart`)**:
   - Kết nối trực tiếp với `favoritePlacesProvider`.
   - Tìm kiếm, lọc theo danh mục ẩm thực OSM và sắp xếp tiếp tục hoạt động mượt mà.

## Kiểm chứng và Test

- Bộ test mới: `test/firestore_favorite_repository_test.dart` (5 tests pass):
  - Validate empty userId/placeId.
  - Thêm/xóa favorite trong collection Firestore.
  - Lắng nghe stream snapshots cập nhật danh sách.
  - Giải quyết Place model cho cả quán demo và quán OSM thật.
- Bộ test hồi quy: `test/favorites_screen_test.dart` (2 tests pass).
