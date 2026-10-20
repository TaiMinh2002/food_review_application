# T17 — My Profile

Màn `/profile` được đối chiếu với Stitch screen `11 - My Profile` (`90955d97ade5418f8ce5c32e2202ee8b`). UI gồm header Cá Nhân, avatar, thông tin phiên hiện tại, thống kê, chỉnh sửa hồ sơ, hoạt động, danh mục cá nhân, tài khoản/hỗ trợ và bottom navigation của app shell.

Các lối vào Đánh giá của tôi, Favorites, Want to Visit, Collections, Notifications, Settings và Edit Profile dùng `AppRoute` hiện có. Guest vẫn thấy profile shell và được mời đăng nhập; session loading/error không hiển thị nội dung riêng tư.

Profile domain hiện chỉ có `displayName` và `photoUrl`, nên các số liệu follow/review chưa có nguồn dữ liệu thật và hiển thị `—`. T18 đã nối sửa tên/ảnh qua Auth (xem EDIT_PROFILE_UI.md); Collections, Notifications và Settings vẫn là các điểm nối tới task tương ứng. Không giả lập số liệu người dùng.
