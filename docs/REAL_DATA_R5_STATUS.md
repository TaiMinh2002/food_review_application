# R5 — Favorites & Muốn Ghé thật trên Firestore

Cập nhật 23/10/2026.
- Favorites: triển khai trên nhánh `feat/favorites`, đã merge vào `dev`.
- Want-to-Visit (Muốn ghé): triển khai trên nhánh `feat/want-to-visit`, base từ `origin/dev`.

## Đã nối và chuẩn hóa

### 1. Favorites (`users/{uid}/favorites/{placeKey}`)
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

### 2. Want-to-Visit (`users/{uid}/wantToVisit/{placeKey}`)
1. **FirestoreWantToVisitRepository (`lib/features/want_to_visit/data/firestore_want_to_visit_repository.dart`)**:
   - Lưu trữ danh sách muốn ghé tại `users/{uid}/wantToVisit/{placeKey}` với timestamp máy chủ `createdAt`.
   - Lắng nghe real-time snapshots qua `watchPlaceIds(userId)`.
   - Thao tác thêm (`doc.set`) và xóa (`doc.delete`) xử lý an toàn lỗi permission và network.
   - Fallback `MemoryWantToVisitRepository` khi chưa có Firebase apps.

2. **wantToVisitPlacesProvider (`lib/features/want_to_visit/presentation/want_to_visit_providers.dart`)**:
   - Độc lập hoàn toàn với danh sách favorites.
   - Giải quyết thông tin quán từ nguồn OSM (`osmRegionPlaceRepositoryProvider`) và demo (`placeRepositoryProvider`).
   - Quán ngoài bán kính 5 km vẫn hiển thị nguyên vẹn.

3. **WantToVisitScreen (`lib/features/want_to_visit/presentation/want_to_visit_screen.dart`)**:
   - Chuyển sang kết nối `wantToVisitPlacesProvider`.
   - Tìm kiếm, lọc và sắp xếp (Mới thêm, Đánh giá cao, Khoảng cách gần) giữ nguyên hành vi mượt mà.

## Kiểm chứng và Test

- Bộ test Favorites:
  - `test/firestore_favorite_repository_test.dart` (5 tests pass).
  - `test/favorites_screen_test.dart` (2 tests pass).
- Bộ test Want-to-Visit:
  - `test/firestore_want_to_visit_repository_test.dart` (5 tests pass).
  - `test/want_to_visit_screen_test.dart` (2 tests pass).
- Toàn bộ test suite 416 tests pass, static analysis clean, dart format clean.
