# R4 — Reviews & Ảnh Cloudinary trên Firestore

Cập nhật 23/10/2026. Triển khai theo từng bước nhỏ trên các nhánh `feat/`:

## Tiến độ các bước

### Bước 4.1 — Firestore Rules, FirestoreReviewRepository & Cloudinary Photo Upload
- **Nhánh**: `feat/write-review`, đã merge vào `dev`.
- **Đã hoàn thành**:
  1. **Firestore Security Rules (`firestore.rules`)**:
     - Mở quyền tại `places/{placeKey}/reviews/{reviewId}`.
     - Review ID gắn liền với User ID (`reviewId = uid`), đảm bảo mỗi user tối đa 1 bài đánh giá / 1 quán.
     - Kiểm tra dữ liệu: `rating` (1-5), `content` (10-3000 ký tự), các trường `title`, `authorName`, `companion`, `dishes`, `imageUrls`.
     - Owner được create, update, delete bài của chính mình; khách vãng lai chỉ đọc bài có `status == 'public'`.
     - Bộ test rules tại `test/firestore.rules.test.cjs` đã cập nhật kiểm tra đầy đủ.
  2. **Cloudinary Photo Upload (`lib/features/reviews/data/cloudinary_review_photo_uploader.dart`)**:
     - Upload ảnh thực tế từ thiết bị lên Cloudinary qua unsigned upload preset.
     - Nhận URL bảo mật `secure_url` và lưu vào bài đánh giá.
  3. **FirestoreReviewRepository (`lib/features/reviews/data/firestore_review_repository.dart`)**:
     - Triển khai `create`, `update`, `delete`, `watchForPlace`, `getReview`.
     - Xử lý các lỗi mạng, phân quyền và dữ liệu thành `AppException`.
     - Tự động fallback về `DemoReviewRepository` khi chưa khởi tạo Firebase.
  4. **WriteReviewScreen & Controller (`lib/features/reviews/presentation/`)**:
     - Bỏ việc tự động gán ảnh của nhà hàng vào form đánh giá của người dùng.
     - Cho phép chọn nhiều ảnh thực tế từ thư viện, upload và lưu URL thật.
     - Chống submit trùng lặp, giữ nguyên dữ liệu draft khi gặp lỗi.
  5. **Kiểm thử**:
     - `test/firestore_review_repository_test.dart` (7 tests pass).
     - `test/write_review_screen_test.dart` (8 tests pass).

### Bước 4.2 — Feed, Phân trang All Reviews & Thống kê điểm (ReviewFeedRepository)
- **Nhánh**: `feat/all-reviews-ui`, base từ `origin/dev`.
- **Đã hoàn thành**:
  1. **Triển khai ReviewFeedRepository trên FirestoreReviewRepository (`lib/features/reviews/data/firestore_review_repository.dart`)**:
     - `getSummary(placeId)`: tính toán số lượng tổng `totalCount`, điểm đánh giá trung bình `averageRating`, phân bố số lượng sao `starCounts` (1–5 sao) và số bài có ảnh `withPhotosCount` trực tiếp từ các tài liệu review công khai thật của quán.
     - `getReviews(placeId, filters, cursor, pageSize)`: truy vấn danh sách bài đánh giá có hỗ trợ lọc theo số sao (`rating`), bài có ảnh (`withPhotos`), sắp xếp (`newest`, `oldest`, `ratingHigh`, `ratingLow`) và phân trang dựa trên Firestore cursor `startAfterDocument`.
  2. **Tích hợp ReviewFeedController & AllReviewsScreen (`lib/features/reviews/presentation/`)**:
     - Provider `reviewFeedRepositoryProvider` tự động cung cấp `FirestoreReviewRepository` khi chạy với Firebase.
     - Màn hình `AllReviewsScreen` hiển thị tổng quan điểm thật và nạp phân trang mượt mà.
  3. **Kiểm thử**:
     - Unit tests `test/firestore_review_repository_test.dart` bổ sung kiểm tra `getSummary` và `getReviews` (9 tests pass).
     - Widget tests `test/all_reviews_screen_test.dart` (18 tests pass).

### Bước 4.3 — My Reviews & Gallery thật
- *Dự kiến thực hiện tiếp theo trên nhánh `feat/my-reviews`*.
