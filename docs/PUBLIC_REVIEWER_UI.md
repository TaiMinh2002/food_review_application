# T24 — Hồ sơ người đánh giá công khai

## Thiết kế và điều hướng

- Stitch project `17045709860825880180`, **21 - Public Reviewer Profile**,
  screen `9f6b48808f0d40d690cbf20e6c33b532`; đã đọc screenshot và HTML.
- Route `/users/:userId` trên root navigator, mở bằng push từ tác giả trong
  review hiện có. Guest đọc được public data, không yêu cầu đăng nhập.
- Header dùng tên tác giả, Back về nguồn; direct link Back về Home.
  Bốn tab dùng chung component/destinations của app; chọn tab về shell hiện có.
- Thẻ hồ sơ avatar 80px, tên/handle/khu vực/bio, menu; ba thống kê; bài nổi bật;
  danh sách lazy với Mới nhất/Điểm cao/Có ảnh, cursor paging và refresh/retry.
- Thẻ review mở đúng quán; ảnh mở Gallery với cặp placeId/reviewId và index.
  Quán không tồn tại có nhãn rõ và không mở target; thông tin quán lỗi có retry.
- Menu sao chép **đường dẫn trong app** `/users/:userId` qua Clipboard; chưa có
  universal link/domain chia sẻ công khai. Báo cáo truyền `targetType=user` và
  `userId` sang `/reports/create`. Guest login giữ returnTo. Form gửi báo cáo
  vẫn thuộc T25, không có thông báo gửi thành công giả trong T24.

## Dữ liệu và quyền riêng tư

`PublicReviewerRepository` là read capability độc lập với `UserReviewRepository`
riêng tư. Domain `PublicReviewer` chỉ có trường công khai, không chứa email,
quyền tài khoản hay dữ liệu riêng. Provider dùng cùng nguồn review đã inject;
adapter thiếu capability trả lỗi có retry, không tự chuyển sang demo khác.

`DemoReviewRepository` dùng `DemoPublicReviewerQueries` để đọc các tác giả demo
linh/nam/chau/hai, và `new-reviewer-demo` minh họa hồ sơ chưa có bài. Tên giữ
nhất quán với tác giả trên review. Avatar minh họa từ Stitch được bundle tại
`assets/images/demo/reviewer_avatar.jpg`; handle/khu vực/bio là fixture demo.
Số bài/có ảnh/điểm TB tính từ dữ liệu mẫu đầy đủ của tác giả, không dùng số 36/18
trên thiết kế hoặc số bài của trang đang tải. Bài nổi bật là bài có ảnh với điểm
cao nhất rồi mới nhất. Không tạo badge xác minh hoặc lượt thích chưa có nguồn.

Chỉ review có `isDemo=true` được xuất bản trong adapter demo. Bài mới gửi riêng
tư không tự thành public theo userId. Đây là giới hạn demo, **không phải** quy
tắc xuất bản cho production. Firestore, public profile storage, publication/
moderation status và backend rules chưa tích hợp; backend tương lai phải lọc
published/visible trước count/order/filter/limit và kiểm tra quyền ở server.
Không tái sử dụng query quản lý review riêng tư để dựng hồ sơ công khai.

Controller theo userId, chặn response cũ khi đổi filter/refresh/account, kiểm
tra đúng tác giả và tính hợp lệ của count/paging; đổi session tải lại từ nguồn.
Stream thay đổi review cập nhật hồ sơ/thống kê. Profile thiếu hoặc bị ẩn hiển
thị trạng thái không khả dụng; bài trống khác với lỗi tải và có ảnh trống.

## Kiểm tra

Test gồm guest/read/Back, report ID qua Login, public/private isolation,
summary/sort/filter/paging, stale response, wrong-author rejection, lỗi/retry,
missing/empty, quán bị xóa và tab shell. UI kiểm tra 320/390/428px, chữ 1.6x,
light/dark, render ảnh so với Stitch; màn cuộn, SafeArea và fallback ảnh.

Hướng dẫn chạy riêng: `flutter test test/public_reviewer_test.dart`.

Kết quả Flutter 3.47.5: format không đổi, analyze không có issue, toàn bộ **340
test pass** (15 test T24). Render sáng/tối đã được xem và so với ảnh Stitch;
ảnh thử nghiệm lưu tại `/tmp/t24-stitch/`, không commit file tạm vào repo.

Đã build/run trên iPhone 17 Pro Simulator iOS 26.3, mở trực tiếp hồ sơ demo
không đăng nhập và xem screenshot native. Chưa nghiệm thu backend tài khoản thật.
