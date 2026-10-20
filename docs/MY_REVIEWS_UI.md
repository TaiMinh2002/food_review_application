# T14/T19 — My Reviews và sửa/xóa đánh giá

Màn `/my-reviews` được đối chiếu với Stitch screen **18 - My Reviews** (`668cfe121c04455683c4b017a1990319`) trong project `17045709860825880180`.

## Phạm vi đã triển khai

- Header “Đánh giá của tôi”, mô tả, CTA tạo đánh giá và danh sách review theo tài khoản hiện tại.
- Card review có tiêu đề, ngày, rating, nội dung, ảnh preview và menu “Chỉnh sửa đánh giá”/“Xóa đánh giá”.
- Dialog xác nhận xóa, trạng thái loading/error, empty state và xử lý refresh.
- Tái sử dụng form T13 ở mode edit với dữ liệu prefill, giữ `restaurantId` trong query để lookup theo cặp `(placeId, reviewId)`.
- Auth guard, kiểm tra owner trước khi hiển thị form edit, update/delete qua repository contract, SafeArea, cuộn và light/dark theme.

## Hoàn thiện T19 (20/10/2026)

- Đọc lại HTML/ảnh Stitch màn 18 qua MCP; summary đếm toàn bộ review của user, chip
  Tất cả/Có ảnh/Đã chỉnh sửa có count từ repository, thông tin quán/ảnh đại diện,
  sao/ngày, gallery ảnh và menu mở quán/sửa/xóa trên card. Giữ tiêu đề review đã nhập.
- Không giả badge cộng tác viên, trạng thái duyệt hay số lượt hữu ích khi chưa có dữ liệu.
  Không đưa nút xem thử empty state trong HTML vào app; empty state xuất hiện từ dữ liệu.
- `/my-reviews` nằm trong nhánh Cá nhân của shell, giữ bottom navigation theo Stitch.
  Detail/Edit/Create/Gallery vẫn push trên root; Back giữ filter và danh sách đã tải.
- Query owner/filter trước khi phân trang; mỗi trang mặc định 10, cursor opaque với UI.
  Nút tải thêm, lỗi trang sau giữ dữ liệu và có retry/tải lại; pull-to-refresh thực sự
  chờ request. Summary lỗi không ngăn danh sách tải; nguồn không hỗ trợ báo lỗi rõ.
- `Review.updatedAt` đánh dấu chỉnh sửa; form T13/T14 cập nhật trường này. Thay đổi
  create/update/delete gửi tín hiệu theo user để query lại summary/trang đầu, giữ filter.
  Reload sau mutation quay về trang đầu (10 bài); không giữ cursor cũ sau khi dữ liệu đổi.
- CTA viết bài mở bộ chọn quán dùng Search controller/repository hiện có, hỗ trợ query
  tiếng Việt không dấu, paging/loading/error/empty/retry. Không tự chọn quán đầu tiên.
- Chặn response cũ ghi đè filter/tài khoản mới, chặn response sai owner/filter, bỏ
  kết quả sau dispose. Xác nhận xóa kiểm tra lại session trước khi gọi mutation và
  phản hồi; người khác không thể xác nhận dialog xóa của tài khoản trước.

Adapter review hiện vẫn là RAM demo, dùng quán/ảnh demo hiện có. Không gán review mẫu
của người khác thành bài của user đang đăng nhập. Tài khoản mới có danh sách rỗng;
ảnh chụp test dùng fixture có owner rõ. Firestore/rules, moderation, helpful count,
upload ảnh review và lưu qua restart chưa được tích hợp. Backend phải áp dụng owner
query/rules, cursor ổn định và timestamp server cho `updatedAt`.

## Luồng dữ liệu

`MyReviewsScreen` → `myReviewsControllerProvider` → `UserReviewRepository` (summary,
page và change signal) qua cùng `reviewRepositoryProvider`. Mutation vẫn dùng
`ReviewManagementController` → `ReviewManagementRepository`.
Form edit dùng `WriteReviewScreen(reviewId: ...)` → `ReviewWriteController.updateReview`.
`DemoReviewRepository` kiểm tra owner và lưu update/delete trong RAM để kiểm thử UI; backend Firestore/rules và upload ảnh thật vẫn chưa tích hợp.

## File chính

- `lib/features/reviews/presentation/my_reviews_screen.dart`: màn Stitch, filter, paging, dialog xóa.
- `lib/features/reviews/presentation/my_review_widgets.dart`: summary, card và empty state.
- `lib/features/reviews/presentation/my_reviews_controller.dart`: query/state và chặn stale response.
- `lib/features/reviews/presentation/review_place_picker.dart`: chọn quán dùng capability Search.
- `lib/features/reviews/presentation/review_management_controller.dart`: auth-scoped delete state.
- `lib/features/reviews/presentation/review_providers.dart`: nguồn inject dùng chung và lookup owner-scoped.
- `lib/features/reviews/domain/user_review_repository.dart`: contract truy vấn theo user.
- `lib/features/reviews/presentation/write_review_screen.dart`: form T13 dùng lại cho mode edit.
- `lib/features/reviews/domain/review_repository.dart`: contract quản lý review.
- `lib/features/reviews/data/demo_review_repository.dart`: adapter demo update/delete và owner check.
- `lib/core/router/app_router.dart`: `/my-reviews` và `/reviews/:reviewId/edit?restaurantId=...`.

Test hành vi tại `test/my_reviews_screen_test.dart`, `test/my_reviews_paging_test.dart`
và `test/my_reviews_ui_test.dart`: edit/delete/refresh, counts/filter/paging/retry,
stale response, owner mismatch, đổi session khi dialog mở, chọn đúng quán và Back.
Render light/dark được đối chiếu với Stitch; test 320/390/428px ở text scale 1.6 và
bộ chọn quán trong viewport ngắn có bàn phím.

Kết quả ngày 20/10/2026 (Flutter 3.47.5): format/analyze/diff-check sạch, toàn bộ
267 test pass. App build/chạy trên iPhone 17 Pro Simulator với `/my-reviews`;
phiên guest chuyển đúng sang Login. Luồng signed-in được kiểm tra qua repository
override và ảnh render; chưa nghiệm thu review backend với tài khoản thật.
