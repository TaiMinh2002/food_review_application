# T13 — Viết đánh giá

Màn `/restaurants/:restaurantId/reviews/create` được đối chiếu với Stitch screen **Food Review — Write Review** (`b8c315ebb4b24143be33f83744c49bdb`) trong project `17045709860825880180`.

## Phạm vi đã triển khai

- Header quay lại, thông tin quán, đánh giá sao 1–5 và nhãn cảm nhận.
- Tiêu đề tùy chọn, nội dung bắt buộc tối thiểu 10 ký tự, bộ tag gợi ý và bộ đếm 1000 ký tự.
- Khu vực ảnh tối đa 6 ảnh, xem trước ảnh demo hoặc ảnh vừa chọn từ thiết bị, xóa ảnh.
- Ngày ghé quán, người đi cùng, hướng dẫn cộng đồng và thanh CTA cố định phía dưới.
- Auth guard giữ `restaurantId`; submit thành công trả về màn nguồn với kết quả `true` để refresh danh sách.
- SafeArea, cuộn, light/dark theme, text scale lớn và viewport 320/390/428dp.

## Luồng dữ liệu

`WriteReviewScreen` → `ReviewWriteController` → `ReviewRepository.create`. `Review` đã có thêm title, visit date và companion để giữ dữ liệu form. `DemoReviewRepository` nhận review vào bộ nhớ cho UI/demo và trả lỗi validation ở repository boundary.

Ảnh chọn từ thiết bị mới chỉ được đọc để xem trước; upload storage/backend chưa có contract nên không được coi là upload thật. Dữ liệu quán và ảnh ban đầu là fixture minh họa. Firebase/Firestore review thật và quyền sở hữu sẽ thuộc phần tích hợp backend.

## File chính

- `lib/features/reviews/presentation/write_review_screen.dart`: form, trạng thái draft và UI Stitch.
- `lib/features/reviews/presentation/write_review_widgets.dart`: các card/section UI của form, tách riêng để giữ giới hạn file.
- `lib/features/reviews/presentation/review_write_controller.dart`: controller Riverpod và submit.
- `lib/features/reviews/domain/review.dart`: model review mở rộng metadata form.
- `lib/features/reviews/data/demo_review_repository.dart`: adapter demo lưu review trong RAM.
- `lib/core/router/app_router.dart`: route create review và auth guard dùng chung.

Ảnh render kiểm tra nằm tại `docs/screenshots/write-review-light.png` và `docs/screenshots/write-review-dark.png`.
