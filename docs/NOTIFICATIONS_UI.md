# T23 — Notifications: đã loại bỏ

Ngày 22/10/2026, người dùng yêu cầu bỏ toàn bộ tính năng thông báo vì không muốn
bật billing cho Cloud Functions. T23 không còn thuộc phạm vi ứng dụng.

- Đã gỡ inbox, route `/notifications`, biểu tượng/menu và badge thông báo.
- Đã gỡ xin quyền thông báo, FCM, cấu hình APNs trong Xcode và quyền Android.
- Đã gỡ code Cloud Functions, rules/index và adapter Firestore vừa chuẩn bị cho luồng này.
- Chưa triển khai functions/rules/index lên Firebase; không thay đổi billing.
- APNs key đã upload trên Firebase Console do người dùng cấu hình trước đó không bị sửa.
- Khởi động vẫn xin quyền vị trí để phục vụ Home/Map; các luồng khác được giữ nguyên.

Kiểm tra sau khi gỡ: format/analyze/diff-check sạch; toàn bộ 370 tests đạt.
`flutter build apk --debug` đạt và manifest trong APK không có `POST_NOTIFICATIONS`.
Plist/project iOS hợp lệ; chưa chạy lại trên iPhone thật, Simulator vẫn tắt theo yêu cầu.
