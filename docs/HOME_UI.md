# Home — dữ liệu quán OSM theo bán kính 5 km

Thiết kế gốc: Stitch `02 - Home`, screen `be51296ba5444ed0b0fc92ac5495ad7a`.
UI đầu tiên triển khai ngày 18/10/2026; nguồn Home được nối sang OSM ngày
23/10/2026 trên nhánh `feat/home-ui`.

Home dùng `homeNearbyPlacesProvider` và `NearbyPlaceRepository` để lấy quán thật
trong 5 km quanh GPS hoặc tâm chọn thủ công. Tâm được chia sẻ với Map; khi GPS
bị từ chối, người dùng có thể chọn Chợ Phùng Khoang. Ngoài vùng gói, màn báo
chưa hỗ trợ và cho thử lại. Không dùng `DemoPlaceRepository` trên Home.

Danh sách lazy hiển thị tên/loại/địa chỉ OSM nếu có và khoảng cách đường chim
bay. Tìm tên không dấu và chip loại quán chỉ lọc tập 5 km đã giới hạn. Card mở
marker đúng quán trên Map; màn chi tiết, Search, Category và quyền ghi favorite/
review vẫn chờ R2–R5 nên Home chưa dẫn vào các luồng demo ấy. Ngày dữ liệu và
© OpenStreetMap contributors hiển thị cạnh danh sách. Không dùng ảnh, rating,
giá, gợi ý cá nhân hay xếp hạng mẫu làm thông tin quán thật.

Home vẫn dùng theme chung và giữ header, lời chào, tìm kiếm, chip, card, Map tab.
Kiểm thử widget gồm gói thật 556 POI quanh Chợ Phùng Khoang, đổi tâm, GPS/thủ
công, lọc tên, và 320 px/chữ lớn ở light/dark. GPS và bố cục native vẫn cần
nghiệm thu trên Android/iOS thực tế. Xem [REAL_DATA_R1_STATUS.md](REAL_DATA_R1_STATUS.md)
để biết phạm vi dữ liệu và các việc R1 còn thiếu.
