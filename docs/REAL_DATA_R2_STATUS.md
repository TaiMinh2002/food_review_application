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

## Restaurant Detail dùng nguồn OSM (23/10/2026)

- Triển khai trên `feat/restaurant-detail-ui`, rebase từ `origin/dev` sau merge Category.
- Hỗ trợ lookup POI OSM độc lập với tâm tìm kiếm hiện tại qua `osmRegionPlaceRepositoryProvider`
  và `OsmRegionPlaceRepository` (implement cả `NearbyPlaceRepository` và `PlaceRepository`).
- Tên, danh mục OSM (Nhà hàng, Cà phê, Ăn nhanh, Khu ẩm thực), địa chỉ thật nếu có và
  khoảng cách đường chim bay từ tâm khám phá (nếu đã chọn tâm) hoặc tọa độ GPS.
- Dữ liệu thiếu được xử lý trung thực: không bịa ảnh, menu hay rating giả; quán chưa có
  review hiển thị "Chưa có đánh giá" và "Hãy là người đầu tiên chia sẻ cảm nhận về quán".
- Ghi rõ attribution: "Dữ liệu nguồn OpenStreetMap · © OpenStreetMap contributors (ODbL)".
- Tích hợp "Chỉ đường": nút Chỉ đường cố định ở thanh giá mở ứng dụng bản đồ bên ngoài
  (Google Maps / Apple Maps qua `walkingDirections` và `openMapLink`), nút "Xem trên bản đồ"
  mở màn hình Map nội bộ tại đúng quán.
- Bộ test mới: `test/osm_place_detail_test.dart` (14 tests pass, gồm visual capture light/dark).
  Toàn bộ `test/place_detail_test.dart` (16 tests pass) vẫn hoạt động nguyên vẹn.

## Phần còn lại

- Bộ chọn quán Review/Collections và các capability persistence vẫn theo đợt
  riêng (R3–R7). Chưa import catalog Firestore hoặc mở ghi review/favorite thật.
- Chưa nghiệm thu thao tác thực tế Android/iOS, GPS/restart/mở ứng dụng chỉ đường
  và đối chiếu quán đang hoạt động. Chưa xác nhận chất lượng/phủ kín OSM thực địa.
- Ngoài bbox gói hiện tại cần gói dữ liệu bổ sung; không fallback demo hoặc gọi
  Overpass công khai như backend production.
