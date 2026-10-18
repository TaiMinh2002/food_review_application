# Kiến trúc và quy ước

## Luồng phụ thuộc

```text
Screen / Widget → Riverpod provider → Repository contract (domain)
                                      ↑ implementation (data)
                                      → Firestore / Auth / HTTP (sau này)
```

Domain chứa model Dart thuần và contract. Data implement contract và chịu trách nhiệm
mapping DTO, Timestamp, exception SDK. Presentation chứa UI và state.
Core là thành phần toàn app; shared chỉ nhận widget/model thực sự tái sử dụng.
Không đưa logic tính năng vào core hoặc dựng use case khi chưa có nghiệp vụ cần tái sử dụng.

## Stack và nền tảng

Flutter/Dart cho Android/iOS; Riverpod quản lý dependency/state; go_router giữ stack tab;
Material 3 và Inter cho UI. Firebase Auth quản lý danh tính, Firestore lưu dữ liệu,
Cloudinary + HTTP/image_picker cho ảnh, flutter_map/OSM + geolocator/latlong2 cho vị trí.
Package đã khai báo không đồng nghĩa đã tích hợp; Firebase native đã khởi tạo nhưng
chưa có repository Auth/Firestore thật. Web cần FirebaseOptions riêng.
Không thêm code generation, service locator hoặc base repository tổng quát khi chưa cần.
Phạm vi/trạng thái/lộ trình ở [FEATURES.md](FEATURES.md); schema, query và phân quyền ở
[BACKEND_SETUP.md](BACKEND_SETUP.md).

## Dependency injection

`ProviderScope` ở main; `placeRepositoryProvider` đang cấp `DemoPlaceRepository`.
Khi có Firestore, thêm implementation mới ở places/data và đổi provider.
Không tạo Firestore instance trong widget. Test có thể override provider mà không kết nối mạng.

`FavoriteRepository` hiện là contract đồng bộ dành cho demo RAM. Trước khi nối Firestore,
đổi sang `watchPlaceIds(userId)` và async `setFavorite(userId, placeId, value)`;
chuyển notifier sang async state, xử lý lỗi ghi và reset khi đăng xuất.
Không bọc API Firestore async bằng contract đồng bộ hiện tại.

## Routing

- `/home`: màn khám phá hiện có; Home theo Stitch chờ T03.
- `/restaurants/:restaurantId`: chi tiết; map ID sang `placeId` trong domain, xử lý ID không tồn tại.
- `/map`: tab placeholder, chờ T08.
- `/favorites`: quán đã lưu trong phiên.
- `/profile`: trang khởi đầu hồ sơ.
- `/login`: thông báo tích hợp Auth đang chờ cấu hình.

Bốn tab dùng indexed stack giữ search/filter khi chuyển tab. Router thuộc provider và được dispose.
`AppRoute` định nghĩa route có tên và helper encode tham số. URL `/places`, `/places/:placeId`,
`/sign-in` cũ redirect về canonical route và giữ query. Detail được push trên root navigator;
Back pop về nguồn, direct link không có history thì về Home. Các route chưa có feature dùng
placeholder có task ID; admin bị từ chối mặc định. Xem [UI_FOUNDATION.md](UI_FOUNDATION.md).
Sau khi có Auth: thêm redirect cho viết review/yêu thích cá nhân, theo dõi auth stream và giữ
địa chỉ đích sau đăng nhập; khách vẫn được xem quán. Chưa áp dụng guard trong demo.

## Quy ước code

- `snake_case.dart`, class `PascalCase`, biến/hàm `camelCase`.
- Model domain không phụ thuộc SDK Firebase; dùng `DateTime` và mapper ở data.
- Không xuất thông báo exception SDK trực tiếp ra UI; map thành `AppException`.
- Dùng `AsyncValue.when` cho loading/error/data, có empty state và retry.
  Places provider tắt auto retry để hiển thị lỗi ngay; người dùng chủ động bấm Thử lại.
- Controller/TextEditingController, subscription và HTTP client phải được giải phóng theo lifecycle.
- Kiểm tra dữ liệu ở UI để phản hồi nhanh, repository/domain cho tính nhất quán,
  và Firestore rules/backend cho quyền thực tế.
- Cấu hình compile-time chỉ chứa giá trị được phép công khai; không thể giấu secret trong app build.

## Kiểm thử

Base có kiểm thử tìm/lọc, validation review, thay đổi yêu thích, điều hướng chi tiết và trạng thái
error/empty/not-found qua override repository. Khi triển khai Firebase, bổ sung emulator tests
cho quyền truy cập; khi triển khai native, kiểm tra quyền và upload trên thiết bị.
