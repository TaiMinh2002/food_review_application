# T09b — Thư viện ảnh

Ngày triển khai: 19/10/2026. Branch: `feat/gallery-ui`.
Trạng thái: UI/demo đã triển khai, chờ người dùng duyệt và tích hợp backend.
Task tiếp theo theo kế hoạch là **T10 — Login/Auth**, trước các thao tác cá nhân.

## Nguồn và bố cục

Đã đọc ảnh và HTML qua Stitch MCP từ
[project Food Review](https://stitch.withgoogle.com/projects/17045709860825880180),
màn **07 - Restaurant Gallery**, title `Food Review — Restaurant Gallery`,
screen ID `5de6740efe3f4995b875f518c83b2680`.

AppBar có Back, tiêu đề/tên quán, chia sẻ và lối vào Cá nhân. Ảnh đầu trang 4:3,
caption/tác giả, bộ lọc ngang, lưới ảnh vuông hai cột gap 12 và khối Đăng ảnh ở cuối
theo thiết kế. Root route `/restaurants/:restaurantId/gallery` không có thanh bốn tab;
CTA đóng góp nằm trong luồng cuộn như Stitch. Nội dung tối đa 680px, lề 20, góc 12,
font Inter và màu ngữ nghĩa từ theme hiện có. Có light/dark, SafeArea và text scaling.

## Luồng và định danh ảnh

- Mở thư viện không có `index`: hiện lưới. Có `index`: tự mở trình xem ở ảnh đó
  một lần; đóng trình xem trở lại thư viện, Back tiếp trở về nguồn.
- Từ Chi tiết quán: giữ nguyên thứ tự `Place.imageUrls`, sau đó mới thêm ảnh metadata
  chưa có. Không thay ảnh hoặc số lượng ảnh trong carousel chi tiết cũ.
- Từ preview/All Reviews: `source=review&reviewId=...&index=...` lấy đúng review bằng
  cặp `(placeId, reviewId)` qua capability `ReviewMediaRepository`; không dùng preview
  giới hạn hai bài để tìm review khác. Không có/khác quán/nguồn chưa hỗ trợ thì báo lỗi,
  không tự chuyển sang ảnh quán.
- Index dùng số nguyên từ 0; malformed/âm về đầu, vượt phạm vi về cuối. Zero ảnh
  có empty state và CTA đóng góp, không tạo PageController với chỉ số sai.
- Trình xem toàn màn hình có số thứ tự, caption/tác giả, đóng, vuốt, nút trước/sau,
  `InteractiveViewer` phóng to tối đa 4× và chia sẻ. Ảnh giữ tỷ lệ bằng `BoxFit.contain`.
- Lọc Món ăn/Không gian/Thực khách/Ảnh khác từ metadata, đếm từ snapshot đang có.
  Ảnh nổi bật giữ ở đầu; grid lọc phần còn lại. Tap grid xem trong tập đã lọc;
  bộ đếm của viewer phản ánh tập đó. Không có metadata thì dùng Ảnh khác.
- Filter và vị trí cuộn giữ khi đóng viewer, share sheet hoặc Back từ màn con.
  Đổi quán/nguồn sẽ reset state; response cũ không thay thế nguồn mới.
- Chia sẻ tái sử dụng sheet Clipboard: đường dẫn nội bộ chứa quán, nguồn review
  và index trong tập gốc, kể cả khi đang xem nhóm lọc. Chưa có native share/public link.
- Ảnh lỗi có retry theo từng ảnh; loading ảnh mạng có trạng thái riêng. Lỗi thư viện,
  lỗi quán và không tìm thấy quán có thông báo/retry riêng.

## Dữ liệu mẫu và phần chưa tích hợp

Phở Nhà Mình có **7 ảnh mẫu**: 4 món ăn, 2 không gian, 1 thực khách.
Giữ 4 assets/thứ tự cũ, thêm `gallery_space.jpg`, `gallery_front.jpg`,
`gallery_guests.jpg` tải từ các URL ảnh trong HTML Stitch của màn Gallery.
Các ảnh chỉ để minh họa bố cục, không xác minh quán, người chụp hay trải nghiệm.
Một asset cũ `detail_hero.jpg` chứa cả mockup UI từ task T04; được giữ nguyên để
không thay carousel/ảnh đang có. Tên quán hiện tại được giữ, không đổi theo tên mẫu Stitch.

`demo_gallery_photos.dart` chứa category/caption/tác giả minh họa; không gán tên người
chụp thật cho assets quán. Ảnh review lấy authorName/isDemo từ chính review.
Không chép 24/14/6/4 ảnh hoặc số likes của Stitch khi chưa có dữ liệu.

Tim lưu ảnh bị khóa kèm giải thích; không dùng favorite quán để giả lưu ảnh.
“Đăng ảnh” mở sheet nói rõ chưa tích hợp và có lối vào placeholder T13 đúng quán;
chưa chọn/upload/lưu ảnh, không xin quyền ảnh hoặc báo thành công giả. Auth và upload
thuộc T10/T13; không mở rộng task này sang chức năng ghi dữ liệu.

## File và trách nhiệm

| File | Trách nhiệm |
| --- | --- |
| `places/domain/gallery.dart` | Photo/category/snapshot bất biến, request URI và chuẩn hóa index |
| `places/domain/gallery_repository.dart` | Contract đọc media snapshot theo place/request |
| `places/data/place_gallery_repository.dart` | Ghép dữ liệu đang inject, giữ index, exact review lookup, kiểm tra scope |
| `places/data/demo_gallery_photos.dart` | Metadata ảnh demo tách khỏi widget |
| `places/presentation/gallery_providers.dart` | DI, FutureProvider autoDispose theo request, lỗi/retry chủ động |
| `places/presentation/gallery_screen.dart` | Trạng thái quán/ảnh, lọc, scroll, điều hướng và CTA |
| `places/presentation/gallery_widgets.dart` | Featured, tile, đóng góp responsive và ảnh lỗi/retry |
| `places/presentation/gallery_viewer.dart` | Dialog toàn màn hình, PageController dispose, zoom/swipe/counter |
| `reviews/domain/review_repository.dart` | Capability exact review media, giữ contract preview/create cũ |
| `shared/widgets/app_image.dart` | Thêm fit và loadingFallback tùy chọn; mặc định cũ giữ nguyên |

Các đường dẫn feature trong bảng nằm dưới `lib/features/`.
`Place.galleryPhotos` là metadata tùy chọn; backend cần giới hạn snapshot media trên
document/query, exact lookup chỉ đọc review hiển thị và xác minh scope/quyền phía server.
Không scan toàn bộ review hoặc tải toàn backend để lọc trong widget.
Nếu triển khai album lớn, bổ sung query/cursor media riêng trước khi tăng giới hạn snapshot.

## Kiểm chứng

- Unit tests: thứ tự ảnh và phần bổ sung, snapshot bất biến, index/URI, exact lookup
  cả review ngoài preview, sai quán/review thiếu.
- Widget tests: 320/390/428px, text scale 1/1.6, light/dark, SafeArea; viewport ngang
  thấp với chữ lớn; vuốt/nút chuyển/counter, lọc và share đúng index, Back giữ scroll,
  empty/missing/ảnh hỏng/retry, loading/error và response cũ sau đổi route.
- Đã cập nhật kiểm tra từ Chi tiết và All Reviews để xác nhận viewer thật, đúng ảnh,
  đóng viewer rồi Back về nguồn. Không còn phụ thuộc placeholder Gallery.
- Đã build/run main thật trên iPhone 17 Pro simulator (Flutter 3.47.5), hot reload và
  chụp runtime qua Flutter inspector. Chưa nghiệm thu thao tác native trên máy thật;
  simulator có hộp thoại Apple Account Verification cản tương tác ở các lượt kiểm tra.
- Đối chiếu ảnh với Stitch: giữ tỷ lệ hero/grid, lề, góc bo, footer ảnh và khối đóng góp;
  chỉnh caption/arrow/heart và bố cục CTA sau render. Ảnh render 390×1400 gồm SafeArea
  và nhãn dữ liệu mẫu; ảnh Stitch gốc không có phần SafeArea thiết bị này.
- Kiểm tra cuối: format không thay đổi, `flutter analyze` không có lỗi,
  toàn bộ **165 tests pass**, `git diff --check` sạch. Các file mới đều dưới 700 dòng.

Ảnh: [light](screenshots/gallery-light.png), [dark](screenshots/gallery-dark.png),
[viewer light](screenshots/gallery-viewer-light.png), [viewer dark](screenshots/gallery-viewer-dark.png),
[iOS light](screenshots/gallery-ios-light.png), [iOS dark](screenshots/gallery-ios-dark.png).

Tái tạo ảnh: `flutter test test/gallery_test.dart --dart-define=GALLERY_CAPTURE=true`.
Kết quả ở `build/gallery-screenshots/`. Kiểm tra cuối theo `rule.md`: format, analyze,
full tests và `git diff --check`.
