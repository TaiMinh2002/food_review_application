# T14 — Sửa/xóa đánh giá

Màn `/my-reviews` được đối chiếu với Stitch screen **18 - My Reviews** (`668cfe121c04455683c4b017a1990319`) trong project `17045709860825880180`.

## Phạm vi đã triển khai

- Header “Đánh giá của tôi”, mô tả, CTA tạo đánh giá và danh sách review theo tài khoản hiện tại.
- Card review có tiêu đề, ngày, rating, nội dung, ảnh preview và menu “Chỉnh sửa đánh giá”/“Xóa đánh giá”.
- Dialog xác nhận xóa, trạng thái loading/error, empty state và xử lý refresh.
- Tái sử dụng form T13 ở mode edit với dữ liệu prefill, giữ `restaurantId` trong query để lookup theo cặp `(placeId, reviewId)`.
- Auth guard, kiểm tra owner trước khi hiển thị form edit, update/delete qua repository contract, SafeArea, cuộn và light/dark theme.

## Luồng dữ liệu

`MyReviewsScreen` → `myReviewsProvider`/`ReviewManagementController` → `ReviewManagementRepository`.
Form edit dùng `WriteReviewScreen(reviewId: ...)` → `ReviewWriteController.updateReview`.
`DemoReviewRepository` kiểm tra owner và lưu update/delete trong RAM để kiểm thử UI; backend Firestore/rules và upload ảnh thật vẫn chưa tích hợp.

## File chính

- `lib/features/reviews/presentation/my_reviews_screen.dart`: UI Stitch, menu thao tác, dialog xóa và empty/error states.
- `lib/features/reviews/presentation/review_management_controller.dart`: auth-scoped delete state.
- `lib/features/reviews/presentation/review_providers.dart`: lookup owner-scoped và stream My Reviews.
- `lib/features/reviews/presentation/write_review_screen.dart`: form T13 dùng lại cho mode edit.
- `lib/features/reviews/domain/review_repository.dart`: contract quản lý review.
- `lib/features/reviews/data/demo_review_repository.dart`: adapter demo update/delete và owner check.
- `lib/core/router/app_router.dart`: `/my-reviews` và `/reviews/:reviewId/edit?restaurantId=...`.

Test hành vi nằm tại `test/my_reviews_screen_test.dart`; đã kiểm tra edit, delete, owner mismatch và các trạng thái route/auth.
