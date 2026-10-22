# Trạng thái tích hợp dữ liệu thật — R0 và đầu R1

Ngày kiểm tra: 22/10/2026. Nhánh triển khai: `feat/map-ui`, đã rebase lên `origin/dev` trước khi sửa.

## Quyết định đã áp dụng

- Tâm thử nghiệm: Chợ Phùng Khoang, Hà Nội, gần `20.9859, 105.7938`; bán kính khám phá tối đa 5 km theo đường chim bay. Tọa độ này cần đối chiếu trên thiết bị trước nghiệm thu vùng.
- ID quán từ OSM: `osm_<node|way|relation>_<positive id>`. Tên và tọa độ bắt buộc; địa chỉ có thể trống. Không suy ra rating, ảnh, giá hay menu từ OSM.
- Danh mục Firestore `places/{placeKey}` chỉ là tham chiếu quán đã đăng ký bởi công cụ tin cậy. Client được `get` quán active, không được list hoặc tự ghi catalog. Khám phá 5 km sẽ dùng gói OSM khu vực có spatial index, không đọc toàn bộ catalog Firestore.
- `users/{uid}` là hồ sơ public giới hạn các trường displayName, photoUrl, bio, region và timestamp/trạng thái. Email và role không được ghi. Favorites và wantToVisit là hai subcollection độc lập, owner có quyền đọc/tạo/xóa; chỉ lưu ID quán active đã đăng ký.
- Review, collection và report còn đóng trong rules cho đến khi adapter, schema validation và tests của các đợt tương ứng hoàn tất. Rules hiện tại chưa triển khai cho production: app vẫn chạy các demo adapter cũ.

## Query/quyền hiện tại

| Đường dẫn | Guest | Owner | Tài khoản khác | Ghi từ client |
| --- | --- | --- | --- | --- |
| `places/{placeKey}` | `get` active | `get` active | `get` active | Không |
| `users/{uid}` | `get` active | `get` active | `get` active | Owner tạo/sửa field public hợp lệ |
| `users/{uid}/favorites/{placeKey}` | Không | `get/list`, tạo/xóa | Không | Owner, timestamp server, target active |
| `users/{uid}/wantToVisit/{placeKey}` | Không | `get/list`, tạo/xóa | Không | Owner, timestamp server, target active |
| Review, collection, report | Không | Không | Không | Không |

## Bằng chứng và giới hạn

- Mapper và nguồn Overpass **chỉ dùng để đo dữ liệu trong phát triển** có unit test: node/way/relation, tên/ID/tọa độ, bán kính, cache, response lỗi. Chưa nối nguồn này vào provider mặc định; public Overpass không phù hợp làm backend đại chúng.
- Lần gọi Overpass công khai từ máy phát triển cho vùng thử nghiệm nhận HTTP 406 hoặc timeout. Vì vậy chưa có số POI thật, thời gian đáp ứng hay đối chiếu quán quen; cổng nghiệm thu R1 chưa đạt. Không thay bằng quán giả.
- Firestore emulator đã chạy 4 nhóm rules test cho guest/owner/user khác, catalog active/hidden, field giả, favorites/wantToVisit và các path còn đóng. Chạy `npm ci` rồi `npm run test:rules` với JDK 21+; bản Firebase CLI được khóa trong `package-lock.json`. Chưa deploy rules, import catalog hay xác nhận Firebase Console.
- Cần người có quyền Console xác nhận project ở Spark, bật Auth email/password, quota Firestore và cấu hình Cloudinary Free. Không cần Google Maps/Places key; không bật billing hay nâng gói.
- Tiếp theo: xác minh nguồn extract OSM hợp lệ cho Hà Nội, xây gói khu vực và truy vấn spatial tại thiết bị; kiểm chứng ít nhất ba tâm thực tế, gồm Chợ Phùng Khoang. Chỉ sau đó mới chuyển Home/Map/Search sang provider thật.
