# T25 — Báo cáo nội dung

## Thiết kế và luồng

Đọc screenshot/HTML Stitch project `17045709860825880180`, màn **23 - Report Content**
(`14a53993bfc748efb8b18252d0f148f3`). Form root `/reports/create` có header/Back,
thẻ nội dung, sáu lý do radio chưa chọn mặc định, mô tả 500 ký tự, tối đa ba ảnh,
ghi chú và Gửi/Hủy. Không có tab dưới hoặc phần xem thử modal dành cho tester.
Hủy/Back khi có nháp hỏi xác nhận; lỗi giữ nguyên lý do, nội dung và ảnh.
Thành công chỉ hiện sau repository trả receipt; Đóng & Quay lại về nguồn, direct
link về Home. Chưa báo nội dung đã được kiểm duyệt hoặc hứa thời hạn xử lý.

Target dùng enum và ID; không nhận URL tùy ý hoặc dùng tên làm định danh:

| Loại | Query hiện có |
| --- | --- |
| Quán | `targetType=place&restaurantId=...` (nhận cả alias `restaurant`) |
| Review | `targetType=review&restaurantId=...&reviewId=...` |
| Người dùng | `targetType=user&userId=...` |

Các lối từ Detail/review/Public Reviewer Profile được giữ nguyên. Router yêu cầu
đăng nhập và giữ toàn bộ returnTo; login không tự gửi. Target không hợp lệ,
không tồn tại/đã bị ẩn và tải lỗi có trạng thái riêng, Back/retry phù hợp.
Summary lấy từ repository đang inject, không hiển thị tên/ID/nhận xét giả của
Stitch khi đang báo cáo một nội dung khác.

## Dữ liệu và ảnh minh chứng

`ReportRepository` có `getTarget(target, reporterId)` và `submit(reporterId,
requestId, draft)`. `DemoReportRepository` giải quyết target qua nguồn Place,
exact ReviewMedia lookup theo cặp ID và PublicReviewer capability hiện có.
Review demo được đọc như fixture công khai; bài mới chưa public chỉ cho người
viết đọc để báo cáo, không lộ sang tài khoản khác qua URL đoán ID. Kiểm tra lại
target khi lưu. Backend thực tế phải xác thực reporter và kiểm tra visibility.

Adapter mặc định lưu **RAM của phiên app**, theo reporter/requestId, chưa gửi
đến kiểm duyệt. Form và receipt có thông báo minh họa rõ. Retry cùng request/nội
dung trả cùng receipt, request cũ đổi payload bị từ chối; double tap/concurrent
submit không tạo trùng. Controller và form theo owner/route/target; response cũ
không cập nhật tài khoản mới, draft/ảnh bỏ khi logout hoặc đổi tài khoản.

Chọn ảnh tái sử dụng picker T18 (`ProfilePhotoRepository.pickPhoto`); không gọi
`uploadPhoto` hay gửi ảnh minh chứng lên Cloudinary công khai. Người dùng tự
chọn ảnh, bỏ chọn không thêm; chống ảnh trùng, xem thumbnail/xóa, tối đa 3 ảnh,
5 MB/ảnh, kiểm tra header JPEG/PNG. Không điền sẵn minh chứng mẫu của Stitch.
Picker lỗi/ảnh sai định dạng không làm mất nháp. Bytes được copy bất biến, giữ
cục bộ trong draft và record demo; không ghi log hay file upload. Production cần
private storage, kiểm tra nội dung ảnh ở backend, upload/retry có idempotency và
quyền truy cập theo reporter/moderator trước khi thay adapter. Đây chưa phải
tích hợp moderation, Firestore, persistence hoặc upload evidence production.

## Kiểm tra

Test `test/report_content_test.dart`: target parsing/cặp ID, owner visibility,
target bị xóa, validation/Unicode, chống trùng/retry, picker/remove/format/limit,
lỗi giữ nháp, hủy/system Back, đổi user/late response, quán/review/user context,
320/390/428px chữ 1.6x, keyboard 240px và light/dark. Render ảnh tại
`/tmp/t25-stitch/` để đối chiếu Stitch, không commit ảnh kiểm tra tạm.

Kết quả Flutter 3.47.5: analyze không có issue, toàn bộ **357 test pass**, gồm
17 test T25. Format và diff check sạch. Đã xem render light/dark sau khi chỉnh
căn đầu form trên màn cao; dữ liệu summary và ảnh dùng nguồn hiện có.

Build/run iPhone 17 Pro Simulator iOS 26.3 thành công sau retry khi các tác vụ
Flutter khác đã dừng (lần đầu SPM báo generated Package.swift thay đổi trong build).
Phiên native hiện là guest nên route báo cáo đưa tới Login đúng guard; form,
picker và submit được kiểm tra bằng repository override/widget tests. Chưa
nghiệm thu chọn ảnh thực tế và gửi báo cáo bằng tài khoản/backend production.
