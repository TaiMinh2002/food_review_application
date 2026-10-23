# R2 — Search/Filter và Category dùng nguồn OSM

Cập nhật 23/10/2026. Search đã merge vào `dev` trước đợt này; Category được làm
trên nhánh có sẵn `feat/category-ui`, rebase từ `origin/dev` sau merge Search.
Trạng thái: đã kiểm thử code/UI render; R2 toàn bộ chưa hoàn tất.

## Đã nối

- Home/Map/Search/Category dùng cùng gói OSM Hà Nội, tâm GPS hoặc tâm thủ công,
  giới hạn 5 km. Search/Category dùng `osmSearchControllerProvider` và
  `OsmRegionSearchRepository`, giữ query/scope khi đổi tâm, bỏ response cũ.
- Category áp dụng root AND query/filter trước count/cursor trên toàn tập vùng.
  Các danh mục có nguồn: Nhà hàng, Cà phê, Ăn nhanh, Khu ẩm thực. Bộ lọc lấy
  metadata trong root; không lấy món con từ demo rồi trộn với nguồn OSM.
- Gói hiện chỉ giữ amenity, chưa có cuisine. Deep link danh mục Phở/Bún/Món Việt
  báo chưa hỗ trợ và cho chọn loại quán thật; không suy đoán món từ tên quán.
  Scope sai bị từ chối. URL rating/giá/tiện ích cũ báo thiếu dữ liệu để áp dụng.
- Home có lối vào Category theo loại đang chọn. Card Category mở Map đúng ID và
  Back giữ danh sách/cuộn. Chưa dẫn quán OSM sang Detail nguồn demo.
- Banner không dùng ảnh giả làm ảnh quán. Card thiếu ảnh có placeholder, địa chỉ
  thiếu được ẩn; khoảng cách đường chim bay tính từ tâm chọn, không dùng điểm/giá
  giả. Tạm ẩn CTA lưu RAM và review summary chưa tích hợp trên các card OSM.
- Hiển thị tâm, bán kính, ngày nguồn và attribution. Ảnh render light/dark xem
  [CATEGORY_UI.md](CATEGORY_UI.md).

## Bằng chứng kiểm thử

- Flutter 3.47.5 / Dart 3.13.4; format, analyze và `git diff --check` sạch.
- Toàn bộ suite: **387 tests pass**. Category capture riêng: **23 tests pass**
  (21 test thường + 2 capture). Các test Category dùng chính asset Hà Nội,
  không gọi mạng và không cần Firebase/Google Places key.
- Đối chiếu quanh Chợ Phùng Khoang: 245 Nhà hàng, 245 Cà phê, 62 Ăn nhanh,
  4 Khu ẩm thực; tập phân trang khớp đầy đủ ID của truy vấn 5 km và không trùng.
- Matrix 320/390/428, text scale 1.0/1.6, light/dark; loading/empty/error/retry,
  Cancel/Apply/Reset, sort chưa hỗ trợ, Home → Category → Map → Back, đổi tâm
  và response cũ đã có test. Screenshot là widget render, không phải native.

## Phần còn lại

- Bước tiếp: Detail trên `feat/restaurant-detail-ui`, rebase `dev` sau merge
  Category; lookup OSM ID độc lập tâm hiện tại, xử lý trường thiếu và chỉ đường.
- Bộ chọn quán Review/Collections và các capability persistence vẫn theo đợt
  riêng. Chưa import catalog Firestore hoặc mở ghi review/favorite thật.
- Chưa nghiệm thu thao tác thực tế Android/iOS, GPS/restart/mở ứng dụng chỉ đường
  và đối chiếu quán đang hoạt động. Chưa xác nhận chất lượng/phủ kín OSM thực địa.
- Ngoài bbox gói hiện tại cần gói dữ liệu bổ sung; không fallback demo hoặc gọi
  Overpass công khai như backend production.
