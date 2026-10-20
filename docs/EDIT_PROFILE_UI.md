# T18 — Edit Profile

Nguồn: Stitch MCP, project `17045709860825880180`, screen `12 - Edit Profile`
(`4d24d4281759472db0108f64370d34ea`), đọc HTML và ảnh ngày 20/10/2026.

## Phạm vi đã nối

- `/profile/edit` mở trên root navigator từ My Profile, kể cả nút ảnh đại diện.
  Route giữ auth guard và return-to; editor reset theo user ID, ẩn khi session lỗi/loading/logout.
- Prefill tên và ảnh từ Auth. Tên bắt buộc, tối đa 50 Unicode code points; controller
  kiểm tra lại validation và danh tính trước khi ghi. Chặn lưu trùng trong khi upload/ghi.
- Chọn ảnh từ thư viện, preview/xóa ảnh theo draft; hủy không ghi. Back khi có draft
  yêu cầu xác nhận bỏ thay đổi; direct link quay về Profile khi hủy/lưu.
- `ProfileRepository` cập nhật tên và URL ảnh bằng một thao tác Firebase Auth
  `updateProfile`; không cho chỉnh user ID, email hoặc role.
- `ProfilePhotoRepository` tách chọn ảnh/upload khỏi widget. Adapter dùng image_picker
  và Cloudinary unsigned upload theo cấu hình công khai hiện có. Giới hạn ảnh 5 MB,
  chọn ảnh resize tối đa 1024px, timeout và lỗi riêng. Thiếu cấu hình báo lỗi rõ ràng.
  Nếu upload thành công nhưng ghi Auth lỗi, retry cùng draft dùng lại URL, không upload lại.
- Auth dùng `userChanges()` để My Profile và các review mới nhận tên/ảnh mới. Review
  đã lưu giữ author snapshot cũ; migration/đồng bộ author lịch sử thuộc backend review.

## Thiết kế và giới hạn

Giữ header, avatar/camera, thứ tự trường, nút lưu/hủy, spacing/radius/Inter theo Stitch
và theme app. Screen này ở root, không thêm bottom navigation (ảnh Stitch cũng không có).
Nhãn/hướng dẫn xuống dòng, SafeArea/scroll hỗ trợ keyboard và chữ lớn; dark theo design system.

Username, giới thiệu, khu vực hiển thị disabled và ghi rõ chưa có dịch vụ hồ sơ.
Không lấy username/avatar/bio mẫu của Stitch làm dữ liệu người dùng; không giả badge
khả dụng hoặc nút kiểm thử validation trong app. Các trường này cần contract, uniqueness
và rules Firestore trước khi bật. Vì vậy T18 mới hoàn tất phần tên/ảnh được hỗ trợ.

Chưa nghiệm thu upload Cloudinary/Firebase với tài khoản thật; cần cấu hình upload preset
giới hạn ảnh ở phía dịch vụ. Xóa/thay URL ảnh không xóa file Cloudinary; cleanup asset
upload bỏ dở phải do backend xử lý, không đặt API secret vào client.

## Kiểm tra

Test validation, lỗi/retry giữ draft, bỏ thay đổi, trả về Profile sau lưu, chống submit trùng,
upload lỗi không ghi Auth, retry không upload trùng, đổi user khi đang upload không ghi user cũ.
Test bố cục 320/390/428px, chữ 1.6x, keyboard và hai theme; ảnh render từ widget harness
được đối chiếu với Stitch, không phải bằng chứng nghiệm thu tài khoản thật.

Kết quả ngày 20/10/2026: Flutter 3.47.5; format/analyze/diff-check sạch; toàn bộ
251 test pass. `flutter run --debug --no-resident --route=/profile/edit` build và mở
trên iPhone 17 Pro Simulator thành công; phiên guest chuyển sang Login đúng guard.
