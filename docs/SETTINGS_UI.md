# T20 — Settings

Đối chiếu ngày 20/10/2026 qua Stitch MCP: project `17045709860825880180`,
màn **19 - Settings**, screen `74348ac3dfde4af39bf85773df28f817` (HTML và ảnh 780×2540).

## UI và điều hướng

- `/settings` nằm trong nhánh Cá nhân, giữ bottom navigation bốn tab hiện có.
  Mở từ icon/menu Profile; Back pop về nguồn, direct link Back về Profile.
- Giữ thẻ tài khoản, nhóm Tài khoản/Thông báo/Giao diện/Hỗ trợ, icon nền bo góc,
  divider, nút đăng xuất đỏ nhạt và lời nhắn cuối trang theo Stitch.
  Chỉ dùng một app bar Cài đặt; bỏ header “11 My Profile” lặp từ shell HTML.
- Dùng Inter, token spacing/radius, brand palette và theme light/dark của ứng dụng.
  SafeArea, danh sách cuộn và text scaling không khóa chiều cao từng hàng.
- Tên/ảnh lấy từ `authSessionProvider`; thiếu ảnh dùng initials `AppAvatar`.
  Không dùng người dùng Minh Anh, email, huy hiệu Sành ăn/verified hoặc phiên bản mẫu
  trong Stitch vì domain chưa có nguồn tương ứng. Guest có lối đăng nhập với
  `returnTo=/settings`; session loading/error khóa hành động tài khoản và có retry.

## Hành vi đã nối

- Thẻ tài khoản và Chỉnh sửa hồ sơ mở form T18; Back về Settings.
- Đặt lại mật khẩu mở luồng T12 gửi liên kết email; không giả là đổi mật khẩu trực tiếp.
- Chế độ hiển thị mở bottom sheet Sáng/Tối/Hệ thống, dùng `themeModeProvider` hiện có;
  thay đổi toàn app, giữ khi chuyển route. **Chỉ lưu trong phiên**, khởi động lại dùng
  mặc định hệ thống. Không thêm package persistence; giới hạn này có ghi trên UI.
- `SignOutAction` dùng chung ở Profile và Settings: xác nhận/Huỷ, chống submit trùng,
  lỗi an toàn/retry qua `signOutControllerProvider` → `AuthRepository.signOut()`.
  Xác nhận của user cũ không đăng xuất user mới nếu session đổi khi dialog mở.
  Controller reset theo user ID để không giữ lỗi của tài khoản trước.
- Thành công thay route stack bằng guest Profile, dispose form/draft route riêng tư;
  Back không khôi phục form. Favorites/Want to Visit/My Reviews tiếp tục reset theo
  auth session bằng provider hiện có. Không gọi xóa review hoặc dữ liệu backend.

## Phần chưa tích hợp

Thông báo đẩy (switch tắt và disabled), quản lý quyền hiển thị, trung tâm trợ giúp,
điều khoản và chính sách chưa có dịch vụ/nội dung được công bố; các hàng hiển thị
lý do chưa khả dụng, không điều hướng giả hoặc báo thành công giả. Chưa có lưu theme
qua restart. Không thêm fixture tài khoản vào production; ảnh test dùng `ControlledAuth`.
Các giới hạn RAM demo của Favorite/Want to Visit/Reviews vẫn theo tài liệu từng feature.

## Kiểm chứng

`test/settings_screen_test.dart` kiểm tra đổi theme/route/Back, edit/reset password,
logout Huỷ/lỗi/retry/loading, dọn user state và draft, guard sau logout, đổi tài khoản
khi dialog mở, session loading/error/retry, bố cục 320/390/428px ở text scale 1.6
trong light/dark. `test/auth_routing_test.dart` cập nhật xác nhận logout ở Profile.
Ảnh render light/dark được đối chiếu với Stitch (tạo qua `CAPTURE_SETTINGS=1 flutter test test/settings_screen_test.dart`,
ảnh tạm tại `/tmp/t20-stitch/flutter-{light,dark}.png`).

Kết quả cuối (Flutter 3.47.5): format/analyze/diff-check sạch, **281 test pass**.
Build/chạy debug trên iPhone 17 Pro Simulator; kiểm tra guest Settings, mở sheet,
đổi Tối rồi khôi phục Hệ thống, cuộn footer và đối chiếu bố cục. Căn trái tiêu đề
để thống nhất Stitch trên cả iOS/Android. Luồng signed-in/logout được kiểm tra bằng
repository override, gồm Auth phát guest trước khi future signOut hoàn tất;
chưa nghiệm thu logout/reset password bằng tài khoản Firebase thật trong lượt này.
