# R6 — Collections & Hồ sơ công khai thật trên Firestore

Cập nhật 24/10/2026. Triển khai theo từng bước nhỏ trên các nhánh `feat/`:

## Tiến độ các bước

### Bước 6.1 — Collections & Collection Editor thật trên Firestore
- **Nhánh**: `feat/collections`, base từ `origin/dev`.
- **Đã hoàn thành**:
  1. **Mở Firestore Rules cho Collections (`firestore.rules`)**:
     - Cho phép owner đã xác thực đọc, tạo, sửa, xóa các bộ sưu tập cá nhân tại `users/{uid}/collections/{collectionId}`.
     - Hàm kiểm tra `validCollectionData()`: xác thực tên (1–60 ký tự), mô tả (tối đa 300 ký tự), danh sách `placeIds` (tối đa 50 địa điểm), `coverUrl` tùy chọn, và server timestamp `createdAt`, `updatedAt`.
     - Chặn triệt để người dùng khác và khách vãng lai truy cập bộ sưu tập riêng tư của người khác.
     - Kiểm thử rules cập nhật trong `test/firestore.rules.test.cjs`.
  2. **Triển khai `FirestoreCollectionRepository` (`lib/features/collections/data/firestore_collection_repository.dart`)**:
     - Hiện thực hai hợp đồng domain `CollectionRepository` và `CollectionEditingRepository`.
     - `createCollection`: lưu trữ bộ sưu tập với `requestId` đảm bảo tính lũy thừa (idempotency), tự động lấy ảnh quán đầu tiên làm cover nếu có.
     - `updateCollection`: kiểm tra quyền sở hữu, cập nhật thông tin và cập nhật server timestamp `updatedAt`.
     - `deleteCollection`: xóa bộ sưu tập an toàn.
     - `getCollection`: nạp chi tiết bộ sưu tập kèm metadata các quán được lưu (tên, danh mục, địa chỉ, ảnh).
     - `getCollections`: truy vấn danh sách bộ sưu tập của owner, hỗ trợ sắp xếp (`recent`, `name`, `mostPlaces`) và phân trang cursor.
  3. **Kết nối Provider (`lib/features/collections/presentation/collections_controller.dart`)**:
     - `collectionRepositoryProvider`: tự động kết nối `FirestoreCollectionRepository` kèm hàm tra cứu địa điểm (`PlaceLookup`) kết hợp giữa nguồn OSM và repository hiện hành khi chạy trên Firebase; fallback `DemoCollectionRepository` khi chạy offline/test không có backend.
  4. **Kiểm thử**:
     - Unit tests `test/firestore_collection_repository_test.dart` (11 tests pass).
     - Widget tests `test/collections_screen_test.dart` và `test/collection_editor_screen_test.dart` (21 tests pass).

### Bước 6.2 — Public Reviewer Profile & Thống kê thật
- *Dự kiến thực hiện tiếp theo trên nhánh `feat/public-reviewer-profile`*.
