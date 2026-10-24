# R7 — Báo cáo vi phạm (Report) thật trên Firestore

Cập nhật 24/10/2026. Triển khai theo từng bước nhỏ trên nhánh `feat/report-content`:

## Đã hoàn thành

### 1. Mở Firestore Rules cho Báo cáo & Minh chứng riêng tư (`firestore.rules`)
- Đường dẫn biên nhận báo cáo: `reports/{uid}/submissions/{requestId}`:
  - Cho phép người tạo (reporter) đọc và tạo receipt báo cáo của chính mình (`signedInAs(uid)`).
  - Hàm kiểm tra `validReportSubmission()`:
    - `targetType`: thuộc `['place', 'review', 'user']`.
    - `targetId`: chuỗi hợp lệ (1–200 ký tự).
    - `reason`: thuộc danh mục định sẵn `['inaccurate', 'harassment', 'spam', 'inappropriatePhoto', 'fakeReview', 'other']`.
    - `description`: độ dài tối đa 500 ký tự.
    - `evidenceCount`: số lượng minh chứng hợp lệ (0–3 ảnh).
    - `status`: bắt buộc khởi tạo là `'pending'`.
    - `createdAt`: server timestamp `request.time`.
  - Khóa quyền sửa (`update`) và xóa (`delete`) đối với client để bảo toàn bằng chứng xử lý.
  - Chặn hoàn toàn người dùng khác và khách vãng lai truy cập receipt riêng tư.
- Đường dẫn minh chứng: `reports/{uid}/submissions/{requestId}/evidence/{evidenceId}`:
  - Cho phép reporter lưu minh chứng ảnh riêng tư vào subcollection `evidence`.
  - Không upload lên Cloudinary công khai, đảm bảo tính riêng tư và bảo mật tuyệt đối cho người báo cáo.
  - Kiểm thử rules cập nhật trong `test/firestore.rules.test.cjs`.

### 2. Triển khai `FirestoreReportRepository` (`lib/features/reports/data/firestore_report_repository.dart`)
- Hiện thực hợp đồng domain `ReportRepository` (`isDemo = false`).
- `getTarget`: nạp ngữ cảnh đối tượng cần báo cáo (quán ăn từ OSM/demo, đánh giá qua `ReviewMediaRepository`, hoặc người dùng qua `PublicReviewerRepository`).
- `submit`:
  - Kiểm tra đối tượng báo cáo còn khả dụng.
  - Lưu biên nhận tại `reports/{reporterId}/submissions/{requestId}` đảm bảo tính lũy thừa (idempotency, chống gửi trùng lặp khi retry).
  - Lưu trữ các tệp minh chứng đi kèm vào subcollection `evidence` riêng tư.
  - Trả về `ReportReceipt` thật không phải demo.

### 3. Kết nối Provider (`lib/features/reports/presentation/report_controller.dart`)
- `reportRepositoryProvider`: tự động chuyển sang `FirestoreReportRepository` khi ứng dụng chạy trên Firebase, tích hợp tra cứu quán OSM & demo; fallback `DemoReportRepository` khi chạy offline/test.

### 4. Kiểm thử
- Unit tests `test/firestore_report_repository_test.dart` (7 tests pass).
- Tests hồi quy màn hình báo cáo `test/report_content_test.dart` (14 tests pass).
- Toàn bộ test suite pass, dart format và flutter analyze không có lỗi.
