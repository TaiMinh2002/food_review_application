# T09a — Tất cả đánh giá

Ngày triển khai: 19/10/2026. Branch: `feat/all-reviews-ui`.
Trạng thái: UI/demo đã triển khai và kiểm tra; chưa được người dùng duyệt UI,
chưa tích hợp Firestore. T09b Gallery đã triển khai; xem [GALLERY_UI.md](GALLERY_UI.md).
T10 đã có Auth/guard cho CTA riêng; xem [LOGIN_AUTH_UI.md](LOGIN_AUTH_UI.md).

## Thiết kế và bố cục

Đã đọc ảnh và HTML bằng Stitch MCP từ project
[Food Review](https://stitch.withgoogle.com/projects/17045709860825880180),
màn **05 - All Reviews**, screen ID `83d6c45771db47f4ad73ed324b9b4f32`.

Route `/restaurants/:restaurantId/reviews` mở trên root navigator từ preview chi tiết.
AppBar có Back, tên quán, lọc và chia sẻ; nội dung gồm summary/phân bố sao,
CTA viết, chip lọc, sắp xếp và card nhận xét với ảnh lớn. Thanh viết đánh giá cố định
ở đáy theo Stitch, không thêm thanh bốn tab vào màn này.
Giữ Inter, màu ngữ nghĩa của theme hiện có, khoảng trang 20, card góc 12,
ảnh góc 8 và khoảng cách 8/12/16/24. Nội dung giới hạn 680px ở màn rộng.
SafeArea, cuộn lazy, chữ lớn và thanh CTA co theo nội dung được hỗ trợ.

## Luồng đã triển khai

- Quán loading/error/retry/không tồn tại có trạng thái riêng. Không query review
  hoặc hiện CTA viết khi chưa tìm được quán.
- Summary và danh sách tải/retry độc lập. Lọc theo 1–5 sao và có ảnh kết hợp AND;
  tổng quan luôn giữ số liệu toàn bộ nhận xét của quán.
- Chip ngang; sheet giữ draft, Hủy không áp dụng, Đặt lại chỉ sửa draft,
  Áp dụng mới cập nhật. Sort mới/cũ/điểm cao/điểm thấp có thứ tự ID ổn định khi trùng.
- URL nhận `rating`, `photos=1`, `sort`. Chia sẻ sao chép thông tin cùng đường dẫn
  nội bộ có bộ lọc hiện tại; chưa có universal link/native share mới.
- Phân trang bằng cursor; giữ danh sách khi tải thêm lỗi, retry, chặn request trùng,
  response cũ và dữ liệu sai quán. Back từ màn con giữ filter/vị trí cuộn.
- Avatar mở T24 với userId; tùy chọn mở T25 với restaurantId/reviewId;
  ảnh mở T09b với reviewId và index đúng ảnh; CTA mở T13 với restaurantId.
  Gallery T09b đã có viewer thật và giữ đúng nguồn/index; T14/T24/T25 vẫn thông báo chưa triển khai. T13 trả `true` khi lưu
  thành công, màn tự tải lại summary/danh sách. T13 đã có Auth gate và demo repository; Firestore/backend review thật vẫn chưa tích hợp.

## Dữ liệu mẫu và giới hạn

`DemoReviewRepository` giữ hai review preview cũ và bổ sung hai review cũ hơn để
trình bày bốn card. Tất cả ghi rõ minh họa, ảnh dùng assets demo hiện có.
Phở Nhà Mình có **4 review mẫu, trung bình 4.5, hai 5 sao, hai 4 sao, hai bài có ảnh**;
quán khác có trạng thái chưa có review. Không chép 2.346 lượt hay 4.8 trên Stitch.
Điểm/số review legacy trên Place ở Home/chi tiết là fixture riêng, chưa đồng bộ
với tập review mẫu này; backend phải cung cấp một nguồn thống kê thống nhất.

Không có nguồn xác thực trải nghiệm, cấp foodie, lượt hữu ích hay phản hồi:
không hiện badge/số liệu giả; lọc xác thực và sort hữu ích bị khóa kèm giải thích.
“100% từ 4 sao” là tỷ lệ tính từ histogram mẫu, không phải khảo sát hài lòng.
Thiếu histogram thì hiện thông báo thiếu dữ liệu; không suy ra từ average.

## Các file chính và trách nhiệm

| File | Nhiệm vụ |
| --- | --- |
| `lib/features/reviews/domain/review_feed_repository.dart` | Contract đọc summary/page; filter, sort và snapshot bất biến |
| `lib/features/reviews/data/demo_review_repository.dart` | Fixture riêng, scope/lọc/sort/count trước phân trang; preview và create cũ được giữ |
| `lib/features/reviews/presentation/review_feed_controller.dart` | Riverpod state theo route/quán, retry, cursor, chống stale response |
| `lib/features/reviews/presentation/all_reviews_screen.dart` | Ghép UI, trạng thái quán/review, scroll và điều hướng |
| `lib/features/reviews/presentation/review_feed_widgets.dart` | Summary, chips, sheet lọc/sort, thanh viết responsive |
| `lib/features/reviews/presentation/restaurant_review_card.dart` | Adapter chung dữ liệu/route cho preview và danh sách |
| `lib/shared/widgets/app_review_card.dart` | Variant ảnh lớn; preview thumbnail giữ nguyên |
| `lib/core/router/app_router.dart` | Route thật T09a, nhận ID và query qua seed |

`ReviewFeedRepository` là capability đọc tách khỏi contract preview/create hiện có.
Provider lấy capability từ repository đang được inject; nguồn không hỗ trợ sẽ
hiện lỗi rõ ràng, không tự thay sang demo. Backend phải query quán + status hiển thị,
lọc/sort/count trước limit/cursor; summary toàn bộ quán phải tính phía server.

## Kiểm chứng

- Unit tests: summary từ toàn bộ tập, histogram thiếu/không hợp lệ, dữ liệu bất biến,
  scope quán, filter URI, stable sort/paging, retry độc lập, duplicate/stale/dispose.
- Widget tests: 320/390/428px, text scale 1/1.6, light/dark, SafeArea; lọc AND,
  draft cancel/reset/apply, empty, ID sai, sort, chia sẻ, route ID và Back giữ state.
- Ảnh render toàn trang 390×2064 cùng tỷ lệ ảnh Stitch; kiểm tra lại metric sao,
  bố cục card/ảnh/spacing và thanh viết. Không có overflow trong ma trận layout.
- Build và chạy thành công trên iPhone 17 Pro simulator (Flutter 3.47.5).
  Chụp runtime bằng Flutter inspector; modal xác minh Apple Account của simulator
  cản thao tác UI native, nên chưa nghiệm thu tap/swipe thủ công trên thiết bị thật.
- Kiểm tra cuối: format không thay đổi, `flutter analyze` không có lỗi,
  toàn bộ **140 tests pass**, `git diff --check` sạch.
- Không thay đổi phần map/OSM DNS đang hoãn theo yêu cầu người dùng.

Ảnh: [light](screenshots/reviews-light.png), [dark](screenshots/reviews-dark.png),
[iOS runtime light](screenshots/reviews-ios-light.png),
[iOS runtime dark](screenshots/reviews-ios-dark.png).

Tái tạo ảnh render:
`flutter test test/all_reviews_screen_test.dart --dart-define=REVIEWS_CAPTURE=true`.
Kết quả ở `build/reviews-screenshots/`. Các kiểm tra CI dùng format/analyze/full test
và `git diff --check` theo `rule.md`.
