# Phân tích tài liệu Food Review

## Hiểu mục tiêu

Tài liệu đầu vào mô tả một ứng dụng portfolio trong 4–5 tuần: tìm quán, đọc thông tin,
đăng review có ảnh và lưu yêu thích. Android/iOS là mục tiêu chính. Web/desktop scaffold
được giữ để hỗ trợ Flutter, nhưng chưa cam kết các tích hợp native hoạt động trên mọi nền tảng.

## Đánh giá stack

| Thành phần | Vai trò | Quyết định cho base |
|---|---|---|
| Flutter / Dart | UI đa nền tảng | Material 3, tách root app và entry point |
| flutter_riverpod | Dependency injection, async state | Provider cho repository, FutureProvider cho truy vấn, Notifier cho yêu thích |
| go_router | Route, deep link, tab | StatefulShellRoute giữ state tab; chi tiết mở trên root navigator |
| Firebase Auth | Danh tính người dùng | Contract đã có; cần project thật và bật email/password |
| Firestore | Quán, review, hồ sơ, yêu thích | Schema đề xuất riêng; chưa truy cập ở demo |
| Cloudinary + http + image_picker | Ảnh review | Tích hợp sau Auth; client tuyệt đối không giữ API Secret |
| flutter_map + OpenStreetMap | Bản đồ quán | Triển khai sau dữ liệu thật, cần attribution và chính sách tile |
| geolocator + latlong2 | Vị trí và khoảng cách | Chỉ xin quyền khi người dùng cần; vẫn dùng app khi từ chối |
| Feature-first + Repository | Tách tính năng, dễ thay backend | Domain không import Flutter/Firebase; UI gọi provider |

Stack phù hợp quy mô portfolio. Không cần thêm code generation, use case cho từng thao tác,
service locator hoặc một tầng base repository tổng quát ở giai đoạn này.

## Những điểm tài liệu chưa chốt

1. **Nguồn dữ liệu quán:** đề xuất seed thủ công 10–20 quán; OSM dùng làm bản đồ,
   không mặc định cung cấp danh sách quán, menu và review cho ứng dụng.
2. **Ai thêm/sửa quán:** MVP chỉ quản trị viên qua công cụ seed/console; không cho client ghi places.
3. **Quy tắc review:** đề xuất một review/người/quán để giảm spam, giới hạn nội dung 10–2.000 ký tự,
   tối đa 3 ảnh và kiểm tra kích thước trước upload. Đây là đề xuất cần chốt khi triển khai.
4. **Điểm trung bình:** tính từ dữ liệu review; client không tự ghi tổng điểm vào place.
   Nếu cần aggregate đáng tin cậy, dùng backend hoặc lấy từ tập review phù hợp với MVP nhỏ.
5. **Đồng bộ yêu thích:** demo RAM; phiên bản thật theo tài khoản và lưu Firestore.
6. **Tìm kiếm:** MVP lọc client khi dữ liệu còn ít; Firestore không có full-text search mặc định.
   Cần phân trang và chiến lược tìm kiếm riêng khi quy mô tăng. Chưa hỗ trợ tìm không dấu ở base.
7. **Gần tôi:** tính khoảng cách sau khi lấy GPS; truy vấn địa lý quy mô lớn cần geohash/backend.
8. **Dữ liệu người dùng:** hồ sơ công khai chỉ gồm tên/avatar; không đặt email vào document đọc công khai.

## Phạm vi đã thực hiện

Base chạy độc lập bằng demo repository, có UI danh sách, tìm/lọc, chi tiết, yêu thích,
routing và các contract domain cần thiết. Chưa khởi tạo Firebase vì chưa có cấu hình project;
không tạo tài khoản, repository GitHub hoặc upload dữ liệu bên ngoài.

## Đề xuất MVP

Ưu tiên: khám phá/chi tiết → Auth → dữ liệu thật → review text/sao → yêu thích đồng bộ
→ ảnh → bản đồ/GPS → kiểm thử/portfolio. Nếu thiếu thời gian, chỉ đường ngoài app,
chỉnh sửa hồ sơ nâng cao và bộ lọc nhiều tiêu chí có thể để sau.

Mục tiêu 4–5 tuần là ước lượng theo tài liệu, phụ thuộc thời gian làm thực tế, cấu hình dịch vụ
và kiểm thử thiết bị. Không nên đưa chat, đặt bàn, thanh toán hay gợi ý AI vào MVP.
