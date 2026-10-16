# Danh sách tính năng dự án Food Review

Tài liệu này là phạm vi sản phẩm và backlog triển khai. Ký hiệu trạng thái:

- **Đã có:** chạy được trong base hiện tại.
- **MVP:** cần hoàn thành cho phiên bản đầu tiên.
- **Sau MVP:** chỉ triển khai sau khi các luồng chính ổn định.

## 1. Tài khoản và xác thực

### MVP

- Đăng ký bằng email và mật khẩu.
- Đăng nhập, đăng xuất và duy trì phiên đăng nhập sau khi mở lại app.
- Kiểm tra định dạng email, độ mạnh mật khẩu và hiển thị lỗi dễ hiểu.
- Quên mật khẩu qua email.
- Điều hướng theo trạng thái đăng nhập; khách vẫn xem được địa điểm và review.
- Yêu cầu đăng nhập khi viết review, lưu yêu thích hoặc mở hồ sơ cá nhân.
- Tạo hồ sơ Firestore lần đầu với tên hiển thị, ảnh đại diện và thời điểm tạo.

### Sau MVP

- Xác minh email trước khi đăng review.
- Đăng nhập Google/Apple.
- Xóa tài khoản và dữ liệu liên quan theo một quy trình rõ ràng.

## 2. Khám phá địa điểm ăn uống

### Đã có

- Danh sách địa điểm bằng dữ liệu mẫu.
- Tìm kiếm theo tên, lọc danh mục và mở trang chi tiết.
- Trạng thái loading, lỗi/thử lại, danh sách rỗng và không tìm thấy địa điểm.

### MVP

- Đọc danh sách địa điểm thật từ Firestore và phân trang.
- Tìm kiếm theo tên; chuẩn hóa chữ thường và tiếng Việt không dấu.
- Lọc theo danh mục: nhà hàng, quán ăn, cà phê, đồ uống và món vặt.
- Sắp xếp theo đánh giá, số review hoặc khoảng cách khi người dùng cấp vị trí.
- Hiển thị ảnh đại diện, tên, địa chỉ ngắn, điểm trung bình và số review.
- Dữ liệu quán chỉ do admin/backend quản lý; người dùng không được sửa từ client.

### Sau MVP

- Lọc khoảng giá, giờ mở cửa, tiện ích và bán kính.
- Tìm kiếm toàn văn bằng dịch vụ phù hợp khi số lượng địa điểm tăng.
- Bộ sưu tập nổi bật, địa điểm mới và gợi ý theo sở thích.

## 3. Chi tiết địa điểm

### Đã có

- Thông tin cơ bản, điểm đánh giá, mô tả và thao tác yêu thích bằng dữ liệu mẫu.

### MVP

- Thư viện ảnh, địa chỉ đầy đủ, danh mục và mô tả.
- Điểm trung bình, tổng số review và danh sách review mới nhất.
- Vị trí trên bản đồ, khoảng cách ước tính từ vị trí hiện tại.
- Nút viết review, lưu/bỏ lưu và mở chỉ đường bằng ứng dụng bản đồ ngoài.
- Deep link nội bộ tới địa điểm; xử lý ID không tồn tại.

### Sau MVP

- Giờ mở cửa, số điện thoại, website, menu và tiện ích.
- Chia sẻ link địa điểm ra ứng dụng khác.

## 4. Review và hình ảnh

### MVP

- Tạo review gồm 1–5 sao, nội dung và tối đa một số ảnh được quy định.
- Kiểm tra nội dung, định dạng ảnh và dung lượng trước khi upload.
- Chọn ảnh từ thư viện hoặc chụp bằng camera.
- Upload ảnh lên Cloudinary bằng unsigned preset bị giới hạn.
- Hiển thị tiến trình, lỗi upload, thử lại và chống gửi trùng.
- Lưu review vào `places/{placeId}/reviews/{uid}` để mỗi tài khoản có một review
  cho mỗi địa điểm.
- Hiển thị tên/ảnh người viết, thời gian, số sao, nội dung và ảnh review.
- Sửa hoặc xóa review của chính mình; tài khoản khác chỉ có quyền đọc.
- Cập nhật điểm trung bình và số review bằng backend đáng tin cậy.

### Sau MVP

- Đánh dấu review hữu ích.
- Báo cáo review/ảnh vi phạm và quy trình moderation cho quản trị viên.
- Nén ảnh, thumbnail, dọn ảnh mồ côi và kiểm duyệt nội dung tự động.
- Phản hồi review từ chủ địa điểm nếu có mô hình phân quyền phù hợp.

## 5. Yêu thích

### Đã có

- Thêm/bỏ yêu thích trong bộ nhớ và tab địa điểm đã lưu.

### MVP

- Lưu theo tài khoản tại `users/{uid}/favorites/{placeId}`.
- Đồng bộ trạng thái giữa danh sách, chi tiết và tab đã lưu.
- Khôi phục dữ liệu sau khi mở lại app và tách dữ liệu giữa các tài khoản.
- Xử lý tải, lỗi, danh sách rỗng và thao tác nhanh liên tiếp.

### Sau MVP

- Bộ sưu tập yêu thích riêng và ghi chú cá nhân.

## 6. Bản đồ, vị trí và chỉ đường

### MVP

- Hiển thị OpenStreetMap bằng `flutter_map` với attribution đầy đủ.
- Marker cho địa điểm và mở chi tiết khi chạm marker.
- Xin quyền vị trí đúng lúc người dùng chọn “Gần tôi”.
- Xử lý từ chối quyền, từ chối vĩnh viễn và dịch vụ vị trí đang tắt.
- Hiển thị vị trí hiện tại và khoảng cách đường chim bay tới địa điểm.
- Mở Apple Maps/Google Maps hoặc ứng dụng phù hợp để chỉ đường.
- Chỉ dùng vị trí foreground; không theo dõi nền trong MVP.

### Sau MVP

- Tìm địa điểm trong vùng bản đồ đang xem.
- Truy vấn địa lý theo bán kính và gom marker khi dữ liệu lớn.

## 7. Hồ sơ cá nhân

### MVP

- Hiển thị tên, ảnh đại diện và email của tài khoản hiện tại.
- Chỉnh sửa tên và ảnh đại diện.
- Danh sách review đã viết và địa điểm đã lưu.
- Đăng xuất và liên kết quên mật khẩu.

### Sau MVP

- Thống kê đóng góp, huy hiệu và hồ sơ công khai có kiểm soát quyền riêng tư.
- Cài đặt thông báo, giao diện và ngôn ngữ.

## 8. Dữ liệu, phân quyền và vận hành

### MVP

- Repository thật cho Auth, Place, Review và Favorite, tách khỏi UI.
- Firestore mapper, server timestamp, phân trang và index theo query thực tế.
- Security Rules kiểm tra đăng nhập, owner, field được phép, rating và độ dài nội dung.
- Test rules với guest, owner và tài khoản khác trước khi deploy.
- Firebase Crashlytics hoặc cơ chế ghi lỗi phù hợp cho bản release.
- Firebase App Check sau khi luồng chính ổn định.
- Môi trường development/production và cách quản lý config theo
  `docs/ENVIRONMENT.md`.
- Seed dữ liệu quán bằng script/admin tool sử dụng service account ngoài app.

### Sau MVP

- Backend xử lý aggregate, xóa ảnh và tác vụ chống spam.
- Dashboard quản trị quán, review bị báo cáo và người dùng vi phạm.
- Push notification cho các sự kiện có giá trị, có tùy chọn tắt.

## 9. Chất lượng trải nghiệm

### Đã có

- Material 3, điều hướng ba tab giữ trạng thái và các trạng thái UI cơ bản.

### MVP

- Responsive trên các kích thước điện thoại Android/iOS phổ biến.
- Dark mode, typography, màu sắc và component nhất quán.
- Hỗ trợ bàn phím, vùng chạm, semantic label và cỡ chữ hệ thống.
- Skeleton/loading hợp lý; thông báo lỗi có hành động thử lại.
- Giữ dữ liệu nhập khi upload hoặc ghi Firestore thất bại.
- Tránh gọi mạng trùng, hủy request không còn cần và cache ảnh hợp lý.
- Luồng offline/poor network có thông báo rõ, không làm mất dữ liệu đang nhập.

## 10. Kiểm thử và phát hành

### MVP

- Unit test cho model, mapper, validation và repository logic quan trọng.
- Widget test cho tìm kiếm/lọc, auth form, review form và trạng thái lỗi.
- Test tích hợp luồng đăng nhập → xem quán → review → yêu thích.
- Test Firestore Rules bằng emulator.
- Kiểm thử thật trên ít nhất một thiết bị Android và một thiết bị iOS.
- CI chạy format, analyze và test.
- Cấu hình ký release riêng, không commit keystore/certificate/mật khẩu.
- README có hướng dẫn chạy, ảnh chụp, video demo, giới hạn và kiến trúc.
- Chuẩn bị icon, splash screen, version, privacy policy và metadata cửa hàng.

## Thứ tự triển khai đề xuất

1. Kết nối Firebase Auth và hồ sơ người dùng.
2. Chuyển Place repository từ demo sang Firestore, thêm seed và rules.
3. Hoàn thành review text/rating, sau đó mới nối upload ảnh Cloudinary.
4. Chuyển yêu thích sang Firestore và hoàn thiện trang hồ sơ.
5. Thêm bản đồ, quyền vị trí, khoảng cách và chỉ đường.
6. Hoàn thiện rules, test, accessibility, logging và bản release.

## Ngoài phạm vi phiên bản đầu tiên

Đặt bàn, giao đồ ăn, thanh toán, chat trực tiếp, chương trình khách hàng thân
thiết và mạng xã hội đầy đủ không thuộc MVP. Các tính năng này cần backend,
vận hành và chính sách riêng lớn hơn phạm vi một ứng dụng review ban đầu.
