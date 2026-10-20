# T22 — Collection Editor

Nguồn đọc qua Stitch MCP ngày 20/10/2026:
[project Food Review](https://stitch.withgoogle.com/projects/17045709860825880180),
màn **24 - Collection Editor**, screen `a833546e42dc473dbedbc47410e33449`
(HTML và screenshot 780×4078).

## UI và luồng

- Một form hai mode trên root navigator: `/collections/create` và
  `/collections/:collectionId/edit`. AuthGate/router giữ returnTo; không có bottom
  navigation của shell trong editor. Back/Hủy quay về nguồn, direct link về Collections.
- Bám sát header giữa có icon người dùng, thẻ ảnh bìa, nhóm tên/mô tả, ghi chú riêng tư,
  nhóm địa điểm/count, nút thêm, hàng quán có nút bỏ, helper và dock Lưu/Hủy theo Stitch.
  Dùng Inter, token palette/radius/spacing light/dark, `AppTextField`, `AppButton`,
  `AppBadge`, `AppImage`, overlay/error/skeleton chung.
- Không đưa các panel “Kiểm tra trạng thái & Mô hình con” của HTML vào UI thật.
  Hàng quán dùng thumbnail 52px như thông số HTML, tránh ảnh bị kéo lớn do class
  kích thước không chuẩn trong prototype. Dùng tên/ảnh quán từ repository hiện có,
  không gán tên minh họa của Stitch cho dữ liệu quán khác.
- Prefill edit theo owner/ID; missing, lỗi/retry, loading và nguồn không hỗ trợ có
  phản hồi rõ. Create bắt đầu rỗng. Tên trim bắt buộc, tối đa 60; mô tả tùy chọn tối đa
  300. Counter theo ký tự hiển thị Unicode, validator áp dụng cả ở domain/data và form.
- Cho phép lưu không có địa điểm. Bỏ quán đầu cập nhật cover preview sang quán tiếp
  theo; danh sách rỗng dùng placeholder, cover lưu `null`. Không upload/chọn ảnh thủ công.
- Nút save edit disabled khi chưa thay đổi. Hủy/Back có nháp mở xác nhận Bỏ thay đổi;
  tiếp tục sửa giữ nháp, discard không ghi. Chống lặp dialog; đóng route sau khi PopScope
  được cập nhật để không mở xác nhận lần nữa. Trong lúc lưu khóa sửa/quay lại/submit.
- Dock không che nội dung và được đẩy lên trên bàn phím. Màn chính cuộn lazy; tiêu đề
  hỗ trợ hai dòng/chữ lớn. Sheet trên viewport thấp có bàn phím cuộn cả header/footer.

## Chọn quán

`CollectionPlacePicker` tái sử dụng `searchControllerProvider`/`PlaceSearchRepository`
hiện có: debounce, query không dấu, loading/error/retry/empty và cursor load more.
Không quét feed tại widget và không ngầm thay source inject bằng một demo khác.

Sheet giữ map lựa chọn độc lập theo ID, không mất selection khi đổi query. Quán đã chọn
được đánh dấu; không thể thêm trùng. Đóng sheet không Apply bỏ lựa chọn trong sheet.
Áp dụng chỉ cập nhật draft của editor; chưa ghi repository tới khi Save. Không suy diễn
rằng nguồn search là Favorites như nhãn mẫu trong prototype. Có nhãn nguồn quán mẫu.
Hiện hỗ trợ tối đa **50 địa điểm/bộ sưu tập** để giới hạn snapshot và lookup editor;
count/giới hạn hiển thị trong sheet, data kiểm tra trước khi ghi.

## Dữ liệu và state

- Domain `CollectionDetail`, `CollectionPlace`, `CollectionDraft` và capability
  `CollectionEditingRepository` tách khỏi SDK/Flutter. `CollectionRepository` T21
  (list/delete) giữ tương thích với adapter chỉ đọc.
- `collectionDetailProvider` lookup cặp owner/ID, từ chối snapshot sai owner/ID, trùng ID
  hoặc vượt giới hạn. Form keyed theo owner/route; đổi session bỏ draft cũ. Quán đã mất
  vẫn xuất hiện dưới dạng không khả dụng để người dùng chủ động bỏ; không tự mất membership.
- `collectionSaveProvider` kiểm tra session, gọi create/update, chặn submit trùng và
  response sau dispose/đổi tài khoản. Lỗi giữ toàn bộ form/selection; chỉ toast và về
  danh sách sau khi repository trả thành công.
- Create giữ `requestId` qua retry, adapter tạo đúng một record với cùng request/payload.
  Nếu request đã commit rồi mà payload retry đổi, adapter trả lỗi yêu cầu mở danh sách
  để sửa, không báo thành công cho nội dung chưa được lưu và không tạo bản sao.
- Update giữ nguyên ID, không gọi create. Membership deduplicate và giữ thứ tự; cover
  lấy từ quán đầu, count từ membership. Lookup quán giới hạn theo số ID đã chọn, không
  đọc toàn bộ catalog. Data kiểm tra quán tồn tại, tên/mô tả/giới hạn trước khi ghi.
- Sau mutation refresh T21 giữ sort hiện tại, bỏ cursor cũ. Nếu query danh sách lỗi sau
  khi ghi thành công, T21 có retry; không gửi lại create để chữa lỗi đọc danh sách.
- Collection, Favorites và Want to Visit độc lập. Không gọi xóa/sửa hai repository sau.
  Sheet che selection và đóng khi session thay đổi; callback cũ không áp dụng cho user mới.

`DemoCollectionRepository` hiện lưu trong RAM theo owner trong phiên ứng dụng, có nhãn
mẫu trên cả T21/editor. Chưa có Firestore/persistence. Backend tương lai phải enforce
owner bằng authenticated UID/rules, membership limit, atomic update/cover/count và
idempotency create; không tin ownerId truyền từ form. Xem BACKEND_SETUP.md.

Khai báo trực tiếp `characters` 1.4.1 (đã có trong lock qua Flutter) để domain đếm
ký tự Unicode ghép/emoji giống input formatter, giữ domain độc lập Flutter. Không thêm
package runtime mới vào cây dependency.

## Kiểm thử và đối chiếu

- `collection_editor_repository_test.dart`: tạo/sửa/ID, idempotency, duplicate membership,
  trim/validation, cover/count, empty, sai owner và lookup quán không tồn tại.
- `collection_editor_screen_test.dart`: create/edit với T21, validation, sheet Apply/Cancel,
  search không mất selection, cover, saved lists độc lập, discard/Back, lỗi/retry giữ nháp,
  double-submit, requestId và account switch/late response.
- `collection_editor_ui_test.dart`: 320/390/428px, text scale 1.6, light/dark, bàn phím;
  viewport 320×520 với keyboard 220; CTA vẫn truy cập được và không overflow.
- Test T21 cập nhật từ placeholder sang editor thật và tiếp tục kiểm tra sort/Back.

Render light/dark được đối chiếu screenshot Stitch; ảnh tại
`/tmp/t22-stitch/flutter-{light,dark}.png`, tạo lại bằng
`CAPTURE_COLLECTION_EDITOR=1 flutter test test/collection_editor_ui_test.dart`.

Kết quả ngày 20/10/2026, Flutter 3.47.5: format/analyze/diff-check sạch, toàn bộ
**321 test pass**; test domain Unicode/idempotency được chạy lại sau chỉnh lint.
Đã build/chạy debug trên iPhone 17 Pro Simulator với `/collections/create`; phiên
guest chuyển đúng sang Login. Editor signed-in, sheet và lưu được nghiệm thu bằng
repository override/ảnh render; chưa nghiệm thu Firestore hoặc tài khoản Firebase thật.
