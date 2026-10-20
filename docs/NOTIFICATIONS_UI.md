# Thông báo trong ứng dụng

T23 triển khai inbox tại `/notifications`, đối chiếu Stitch **20 - Notifications**
(`97078d4659e548e89f49e0c2d3c10ef7`). Màn là route gốc, có Back về nơi mở hoặc
Trang chủ khi mở trực tiếp; không có thanh điều hướng dưới trong route này.

## Luồng và trạng thái

- Người dùng đã đăng nhập xem thông báo theo `recipientId`; guest được route guard
  đưa tới Login với `returnTo` nội bộ.
- Danh sách phân nhóm Hôm nay, Hôm qua và Trước đó. Hàng chưa đọc dùng nền nhấn,
  chấm xanh; nút `done_all` đánh dấu toàn bộ đã đọc.
- Chạm một hàng cập nhật trạng thái đã đọc trước khi mở target. Target là enum + ID,
  không nhận URL từ dữ liệu. Target quán được kiểm tra tồn tại; khi đã xóa, UI báo
  nội dung không còn khả dụng.
- Có loading, refresh, load-more, lỗi/retry và trạng thái rỗng. Màn dùng SafeArea,
  scroll và token theme cho light/dark; đã kiểm tra 320px với text scale 1.6.

## Dữ liệu hiện tại

`DemoNotificationRepository` chứa năm thông báo minh họa trong RAM, theo từng tài
khoản và chỉ tồn tại trong phiên app. Ảnh minh họa dùng asset quán có sẵn. Chưa có
Firestore, nguồn tạo thông báo, persistence, hay quyền push; việc xem inbox không
yêu cầu quyền notification của hệ điều hành.

Khi nối backend, chỉ thay adapter theo `NotificationRepository`; backend phải kiểm
tra recipient, pagination và mapping target enum/ID. Không lưu deep link/URL tùy ý.
