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

## Dependency injection

`ProviderScope` ở main; `placeRepositoryProvider` đang cấp `DemoPlaceRepository`.
Khi có Firestore, thêm implementation mới ở places/data và đổi provider.
Không tạo Firestore instance trong widget. Test có thể override provider mà không kết nối mạng.

`FavoriteRepository` hiện là contract đồng bộ dành cho demo RAM. Trước khi nối Firestore,
đổi sang `watchPlaceIds(userId)` và async `setFavorite(userId, placeId, value)`;
chuyển notifier sang async state, xử lý lỗi ghi và reset khi đăng xuất.
Không bọc API Firestore async bằng contract đồng bộ hiện tại.

## Routing

- `/places`: khám phá.
- `/places/:placeId`: chi tiết; tải theo ID, xử lý ID không tồn tại.
- `/favorites`: quán đã lưu trong phiên.
- `/profile`: trang khởi đầu hồ sơ.
- `/sign-in`: thông báo tích hợp Auth đang chờ cấu hình.

Ba tab dùng indexed stack giữ search/filter khi chuyển tab. Router thuộc provider và được dispose.
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
