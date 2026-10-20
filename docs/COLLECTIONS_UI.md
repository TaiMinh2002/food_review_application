# T21 — Collections

Nguồn: [Stitch project](https://stitch.withgoogle.com/projects/17045709860825880180),
màn **22 - Collections**, screen `e69e9a4187db4b23b0025c6237e8f3cd`.
Đã đọc HTML và ảnh thiết kế qua Stitch MCP ngày 20/10/2026.

## UI và phạm vi

- `/collections` nằm trong nhánh Yêu thích của shell, giữ thanh bốn tab theo Stitch.
  Profile chuyển sang nhánh này bằng `go` để tab Yêu thích được chọn đúng; state
  Profile vẫn giữ trong shell. Back về Profile khi không có stack, hoặc pop về nguồn.
- App bar tiêu đề giữa, nút thêm tròn; thẻ giới thiệu, nhãn tổng số bộ sưu tập,
  sắp xếp và card ảnh 4:3 với menu góc phải. Lề 20, gap 12, góc 12; Inter và token
  light/dark hiện có. Lưới hai cột ở kích thước thông thường, một cột khi màn hẹp
  hoặc chữ lớn để không cắt nội dung. SafeArea, cuộn lazy và pull-to-refresh.
- Bỏ các panel xem thử menu/empty của HTML. Menu xuất hiện từ dấu ba chấm;
  empty/loading/error/retry xuất hiện theo dữ liệu thật từ repository.
- Không gán badge Nổi bật hay số quán 12/6/8/10 trong ảnh thành dữ liệu người dùng.
  Count card lấy từ membership độc lập; tổng số bộ sưu tập lấy từ page metadata.
- Menu xóa mở xác nhận; Huỷ không ghi. Thành công bỏ card/query lại và báo kết quả;
  lỗi giữ card, có thể thử lại; chặn thao tác lặp khi đang xóa. Không thay đổi Favorite
  hoặc Want to Visit.
- Tạo mới dẫn `/collections/create`; chạm card/menu sửa dẫn
  `/collections/:collectionId/edit` bằng ID, Back giữ danh sách/sort.
  **Hai route editor vẫn là placeholder T22** theo kế hoạch, có ghi rõ trên UI;
  T21 chưa tạo/sửa tên hoặc membership. Chia sẻ disabled vì collection mặc định riêng tư.

## Dữ liệu và state

`CollectionsScreen` → `collectionsControllerProvider` → `CollectionRepository` →
`DemoCollectionRepository`. Contract phân trang theo owner/sort/cursor/limit (12 item).
Không tải danh sách quán/feed để lọc ở widget. Sort Gần đây nhất/Tên A–Z/Nhiều địa điểm
nhất thực hiện ở repository trước khi phân trang. Cursor demo chứa revision để từ chối
trang cũ sau mutation; UI có retry/tải lại danh sách.

Adapter hiện cấp **4 bộ sưu tập mẫu cho mỗi tài khoản trong phiên ứng dụng**, luôn có
nhãn mẫu trên màn hình. Dữ liệu tách theo owner, số địa điểm là 2/2/1/1 tính từ Set ID
`pho-demo`, `coffee-demo`, `banh-mi-demo`; không lấy membership từ yêu thích/muốn ghé.
Xóa ở tài khoản A không ảnh hưởng mẫu của B. Dữ liệu mẫu không đại diện cho lịch sử lưu
thật của tài khoản. Khởi động lại app tạo lại mẫu; chưa có Firestore hoặc persistence.
Test có thể dùng `DemoCollectionRepository(seedExamples: false)` hoặc override contract
để nghiệm thu empty/error/nguồn khác.

Controller reset theo auth session; guest/loading/error không đọc/hiện dữ liệu riêng.
Generation chặn response query cũ sau đổi sort, refresh, mutation, đổi user và dispose.
Từ chối page sai owner/ID/count, cursor lặp, trang trùng và total không nhất quán.
Dialog kiểm tra lại owner trước xóa; mutation đang chờ của user cũ không refresh/toast
vào tài khoản mới. `AuthGate` và router vẫn giữ returnTo sau login.

Backend tương lai phải kiểm tra authenticated owner ở rules, áp dụng query/limit/cursor
phía dữ liệu, tính count/cover từ membership và xóa membership con khi xóa collection;
không giả định xóa document cha tự dọn subcollection. Schema tại BACKEND_SETUP.md.
T22 bổ sung get/create/update và invalidate/refresh danh sách sau khi lưu.

## Ảnh và kiểm tra

Bốn ảnh bìa lấy từ URL `img.src` trong HTML Stitch, bundle offline tại
`assets/images/demo/collection_{hanoi,date,coffee,budget}.jpg` để không phụ thuộc DNS
khi xem mẫu. `AppImage` giữ fallback theo theme; khung clip/zoom ảnh trong Flutter.
Không thêm dependency hoặc cấu hình bí mật.

Tests: `collection_repository_test.dart`, `collections_paging_test.dart`,
`collections_screen_test.dart`; dùng auth/repository override tại `test/support/`.
Kiểm tra count/membership độc lập, cursor/sort, empty/loading/error/retry/paging,
query stale/sai owner, đổi user, logout, xóa Huỷ/lỗi/retry/submit trùng, route T22/Back,
320/390/428px với text scale 1.6 trong light/dark.
Ảnh render light/dark được đối chiếu Stitch, chỉnh shape/màu nút thêm và menu tròn.
Tạo lại ảnh bằng `CAPTURE_COLLECTIONS=1 flutter test test/collections_screen_test.dart`;
ảnh QA tạm tại `/tmp/t21-stitch/flutter-{light,dark}.png`.

Kết quả cuối ngày 20/10/2026 (Flutter 3.47.5): format/analyze/diff-check sạch,
**300 test pass**. Có kiểm tra sort tên tiếng Việt không dấu và tab Yêu thích được
chọn sau khi mở từ Profile. App build/chạy debug trên iPhone 17 Pro Simulator với
`/collections`; phiên guest chuyển đúng sang Login. UI signed-in và các mutation
được kiểm tra qua repository override/ảnh render; chưa nghiệm thu collection backend
hoặc tài khoản Firebase thật trong lượt này.
