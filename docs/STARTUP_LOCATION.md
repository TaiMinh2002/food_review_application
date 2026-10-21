# Vị trí thiết bị khi mở ứng dụng

## Luồng hiện tại

`main.dart` nạp cấu hình, khởi tạo Firebase rồi chạy `AppPermissionsStartup` bên trong
`ProviderScope`. Sau frame đầu tiên, widget khởi động gọi controller vị trí chung:
kiểm tra dịch vụ vị trí và quyền foreground, xin quyền nếu chưa được cấp, sau đó
lấy một vị trí hiện tại bằng Geolocator. Không chặn mở giao diện trong khi chờ GPS.

- Đã cấp quyền: lấy GPS hiện tại, không tự hiện lại hộp thoại xin quyền.
- Chưa cấp quyền: hiện hộp thoại hệ thống. Từ chối vẫn xem/tìm kiếm quán được.
- Dịch vụ tắt, quyền bị chặn hoặc hết thời gian chờ: hiện lỗi cùng Thử lại/Cài đặt.
- Trở lại từ Cài đặt do app mở: lấy lại vị trí một lần. Resume từ hộp thoại xin
  quyền hoặc chuyển tab không tạo thêm yêu cầu GPS.
- Không có tọa độ mặc định, không lấy vị trí quán/demo làm vị trí người dùng.
- Chỉ lấy foreground fix, timeout 15 giây; không theo dõi vị trí nền.

## Dữ liệu và UI

`userLocationControllerProvider` là nguồn vị trí dùng chung cho Home và Map.
`UserLocationRepository` giữ contract domain, `DeviceLocationRepository` gọi SDK;
UI không gọi Geolocator trực tiếp. Controller chống yêu cầu trùng và không cập nhật
sau dispose. Khi lấy lại vị trí thất bại, xóa fix cũ và tắt lọc Gần tôi thay vì
tiếp tục coi vị trí cũ là hiện tại.

Home hiển thị tọa độ GPS, trạng thái đang lấy/lỗi và nút cập nhật. Chưa tích hợp
reverse geocoding nên không đoán tên thành phố từ tọa độ. Danh sách Khám phá gần
bạn được sắp xếp theo khoảng cách từ fix thật; card hiển thị đường chim bay.
Quán và tọa độ quán vẫn là dữ liệu minh họa tại TP.HCM, chưa đọc Firestore.

Map mở tại fix thật; chưa có fix hoặc vùng xem trước đó thì hiển thị trạng thái yêu cầu vị trí, không
khởi tạo camera tại TP.HCM cố định. Mở Map từ Chi tiết vẫn hiển thị được tọa độ
quán được chọn ngay cả khi không cấp GPS, không gán tọa độ đó cho người dùng.
Vùng bản đồ đã mở tiếp tục kéo/tìm được khi GPS lỗi; chấm vị trí và khoảng cách
người dùng bị xóa, camera không được coi là tọa độ người dùng.
Lỗi DNS tải tile là lỗi mạng riêng, không được giải quyết bằng cấp quyền GPS.
Nền hiện đã chuyển sang MapLibre/OpenFreeMap; xem [NATIVE_MAP.md](NATIVE_MAP.md).

## Các file chính

| File | Trách nhiệm |
| --- | --- |
| `lib/app/app_permissions_startup.dart` | Khởi động GPS và nhận resume; không xin quyền thông báo |
| `lib/features/places/presentation/user_location_controller.dart` | State GPS dùng chung, chống trùng, retry và Cài đặt |
| `lib/features/places/presentation/user_location_status.dart` | Hiển thị fix/loading/lỗi và thao tác phục hồi |
| `lib/features/places/data/device_location_repository.dart` | Quyền/dịch vụ GPS, fix hiện tại và timeout |
| `lib/features/places/presentation/map_controller.dart` | Đồng bộ vị trí chung với tìm quán theo vùng/bán kính |
| `test/startup_location_test.dart` | Quyền SDK, startup, lỗi, chia sẻ tọa độ, resume và layout |

Tham khảo: [Geolocator](https://pub.dev/packages/geolocator).

## Kiểm tra

- Flutter 3.47.5: format sạch, analyze không lỗi, toàn bộ 371 test pass.
- Test quyền mới/đã cấp/denied/deniedForever/GPS tắt/timeout, chống trùng,
  xóa fix khi lỗi, resume từ Cài đặt và đồng bộ Home/Map.
- Layout Home/Map ở 320/390/428px, light/dark, chữ lớn; trạng thái startup bị
  từ chối được kiểm tra riêng ở 320px và text scale 1.6.
- Build/run main thật trên iPhone 17 Pro Simulator thành công. Đã thấy hộp thoại
  xin quyền ngay tại Home, cấp While Using App và thấy Home hiển thị fix của
  Simulator; Map hiển thị chấm vị trí đó và không gán các quán TP.HCM vào vùng khác.
- GPS Simulator là mô phỏng, chưa nghiệm thu GPS trên điện thoại thật. Nền OSM
  vẫn lỗi tải trong môi trường này; quyền vị trí không khắc phục lỗi mạng tile.
