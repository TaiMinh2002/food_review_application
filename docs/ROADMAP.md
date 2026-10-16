# Những việc có thể thực hiện và lộ trình

## Trạng thái base

- [x] Feature-first, repository pattern, Riverpod, go_router, Material theme.
- [x] Khám phá bằng demo data: tìm tên, lọc danh mục.
- [x] Chi tiết và trạng thái không tìm thấy quán.
- [x] Yêu thích trong phiên, đồng bộ giữa danh sách/chi tiết/tab đã lưu.
- [x] Domain Place, Review, UserProfile; contract Auth/Place/Review/Favorite.
- [x] Hướng dẫn cấu hình, schema dự kiến, CI format/analyze/test.
- [ ] Firebase/Auth/Firestore thật.
- [ ] Review UI + lưu server + upload ảnh.
- [ ] Yêu thích theo tài khoản, hồ sơ/review cá nhân.
- [ ] Bản đồ, GPS, khoảng cách, chỉ đường.
- [ ] Kiểm thử Android/iOS và ảnh/video portfolio.

## MVP 4–5 tuần

| Giai đoạn | Công việc | Tiêu chí hoàn thành |
|---|---|---|
| Tuần 1: nền tảng | Base hiện tại; chốt UI và ID ứng dụng; tạo Git/GitHub khi triển khai | Chạy demo, analyze/test pass, xác định rõ fake/real |
| Tuần 2: danh tính + dữ liệu | Firebase, email/password, logout, auth stream; seed quán, mapper Firestore, phân trang | Đăng nhập lại giữ phiên; list/detail dữ liệu thật; xử lý lỗi/empty; rules không cho user sửa quán |
| Tuần 3: review + ảnh + lưu | Form rating/content; upload Cloudinary; chống submit trùng; yêu thích owner-only | Review đọc lại sau restart; tài khoản khác không sửa được; lỗi upload có thể retry; favorite đồng bộ |
| Tuần 4: bản đồ + UX | Marker, attribution, GPS on demand, khoảng cách, hồ sơ và review cá nhân | Từ chối GPS vẫn dùng app; không có quyền nền; test trên Android/iOS |
| Tuần 5: portfolio | Sửa lỗi, accessibility, screenshot/GIF, README, release cấu hình riêng | Không có secret; CI pass; demo các luồng chính, ghi rõ giới hạn |

## Backlog nên làm sau MVP

| Mức ưu tiên | Tính năng | Điều kiện / tác động |
|---|---|---|
| P1 | Sửa/xóa review của mình | Cần rules owner, cập nhật aggregate và xử lý ảnh mồ côi |
| P1 | Quên mật khẩu, xác minh email | Sau Auth cơ bản và thống nhất chính sách đăng review |
| P1 | Tìm không dấu, sắp xếp điểm/khoảng cách | Chốt quy mô dữ liệu; không tải toàn bộ khi dữ liệu lớn |
| P1 | Chỉ đường bằng ứng dụng ngoài | Thêm url_launcher và xử lý không mở được app |
| P2 | Báo cáo review, moderation | Cần quy trình quản trị, không chỉ thêm nút báo cáo |
| P2 | Offline cache, tối ưu ảnh/thumbnail | Đo hiệu năng và chi phí thực tế trước |
| P2 | Bộ lọc giá, giờ mở cửa, tiện ích | Bổ sung dữ liệu có nguồn và cơ chế cập nhật |
| P3 | Gợi ý cá nhân hóa, mạng xã hội | Sau MVP, khi có dữ liệu và yêu cầu rõ |

Không đưa đặt bàn, giao đồ ăn hoặc thanh toán vào phạm vi 4–5 tuần.

## Kiểm chứng trước release

Kiểm tra guest, account A/B, đăng xuất/chuyển tài khoản; review rating/content không hợp lệ;
network timeout/offline; upload một phần; danh sách rỗng; deep link ID sai; bàn phím/màn hình nhỏ;
GPS denied/disabled; ảnh hủy chọn; rules emulator; build Android và iOS trên môi trường hỗ trợ.
Các bước này là backlog kiểm chứng, chưa được thực hiện ở base.
