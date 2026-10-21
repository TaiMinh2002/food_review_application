# Nền bản đồ native cho Flutter

## Nguyên nhân và nguồn tham khảo

`tile.openstreetmap.org` không phân giải DNS trong môi trường kiểm tra, nên cấp
quyền GPS không thể sửa nền trống. Dự án Swift tham khảo ở
`buddy_event_swift/buddyEvent-application-swift/DesignSystem/Components/BEMapPreviewView.swift`
dùng `MKMapView` (Apple MapKit), không dùng raster renderer cũ. Không sửa dự án Swift.

Flutter dùng `maplibre_gl` 0.27.1 để dựng bản đồ native trên iOS và Android,
nguồn vector OpenFreeMap. Đây là SDK khác MapKit, chọn để dùng cùng nền cho hai
hệ điều hành, không cần thêm API key và không gọi host tile OSM đang lỗi.

## Tích hợp

- `NativeMapBackground` hiển thị nền native phía dưới FlutterMap trong cùng Stack.
- FlutterMap là camera/gesture/marker duy nhất. Nền native bỏ gesture riêng và
  nhận camera qua stream; quy đổi zoom 256px/512px để marker khớp đường phố.
- Các lần di chuyển đang chờ được gộp về camera mới nhất, tránh dồn lệnh native.
- Giữ provider truy vấn vùng, GPS dùng chung, marker giá, chọn quán, filter,
  Favorite/Detail và camera khi đổi tab. Native SDK không tự xin thêm quyền GPS.
- Retry chỉ tạo lại nền bản đồ, lấy lại camera hiện tại; không reset vị trí hoặc bộ lọc.
- Timeout tải nền có thông báo và Thử lại; hủy timer/subscription khi dispose.
- Theme sáng/tối lấy style từ `.env`: `MAP_STYLE_URL`, `MAP_DARK_STYLE_URL`.
  Mặc định cả hai dùng Liberty để đường phố và địa danh rõ, không tự đổi sang nền
  Dark gần đen. Nút, card và các lớp UI vẫn theo theme sáng/tối. Khi không cấu hình
  style tối riêng, dùng cùng style tiêu chuẩn thay vì làm tối nền bản đồ.
- Attribution OpenStreetMap/OpenMapTiles/OpenFreeMap hiển thị và có link trên bản đồ.
- Không dùng ảnh bản đồ tĩnh hoặc bản đồ giả khi tải mạng thất bại.

`mapTilesEnabledProvider=false` chỉ dùng trong test để kiểm tra các luồng không
phụ thuộc mạng/platform view; production luôn tạo nền native.

## Nguồn dịch vụ

[MapLibre Flutter](https://pub.dev/packages/maplibre_gl),
[OpenFreeMap quick start](https://openfreemap.org/quick_start/).
Các URL style mặc định được kiểm tra truy cập HTTPS trong môi trường phát triển.
Quán vẫn là fixtures demo ở TP.HCM, chưa phải dữ liệu backend.

## Kiểm tra thực tế

- Flutter analyze sạch, format sạch, toàn bộ 374 test pass.
- Có test riêng cho nền native, attribution, không xin GPS riêng, đồng bộ/coalesce
  camera, quy đổi zoom, style tối, timeout và retry giữ nguyên vùng xem.
- Đã build/run iPhone 17 Pro Simulator, thấy nền đường phố và địa danh thực từ
  OpenFreeMap ở cả giao diện sáng/tối. Đã thao tác zoom, kéo bản đồ, chuyển tab và
  quay về vị trí GPS; nền và marker đồng bộ, camera giữ qua tab và đổi theme.
- Sau phản hồi về nền Dark quá đen, đã dùng Liberty trong cả hai theme và chạy
  lại Simulator: UI tối vẫn hiển thị rõ đường phố, địa danh và zoom bình thường.
- Simulator cung cấp GPS mô phỏng tại San Francisco; các quán demo TP.HCM không
  xuất hiện trong vùng đó là đúng. Chưa nghiệm thu GPS trên điện thoại thật.
- `flutter build apk --debug` thành công; APK tại
  `build/app/outputs/flutter-apk/app-debug.apk`. Chưa chạy runtime trên Android.
- Xcode lần đầu bị chậm ở tải binary SDK. Đã tải archive từ release chính thức,
  kiểm tra SHA-256 khớp manifest SPM và dùng cache SDK để build thành công;
  không sửa source SDK hoặc bỏ kiểm tra checksum.
