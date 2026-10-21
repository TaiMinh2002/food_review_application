# Cấu hình môi trường với dotenv

Ứng dụng dùng duy nhất `.env` ở thư mục gốc để cấu hình môi trường client.
`flutter_dotenv` đọc asset này trong `main.dart`, trước `Firebase.initializeApp()`
và `runApp()`. Các adapter đọc qua `AppConfig`, không đọc file trực tiếp.
Các file JSON cấu hình môi trường cũ đã được bỏ.

## Thiết lập và chạy

```bash
cp .env.example .env
flutter pub get
flutter run
```

Điền Cloudinary cloud name và unsigned upload preset vào `.env`. Nếu máy đã có
file này, giữ các giá trị hiện có thay vì chép đè. Không cần truyền tham số cấu hình
khi chạy hoặc build. Sau khi sửa `.env`, dừng và chạy lại app để nạp asset mới;
hot reload không nạp lại cấu hình.

| Biến | Mục đích | Mặc định khi thiếu hoặc rỗng |
| --- | --- | --- |
| `APP_ENV` | Tên môi trường | `development` |
| `CLOUDINARY_CLOUD_NAME` | Cloud chứa ảnh | Rỗng; upload chưa được cấu hình |
| `CLOUDINARY_UPLOAD_PRESET` | Unsigned upload preset | Rỗng; upload chưa được cấu hình |
| `MAP_STYLE_URL` | Style vector cho giao diện sáng | `https://tiles.openfreemap.org/styles/liberty` |
| `MAP_DARK_STYLE_URL` | Style vector khi UI tối | Theo `MAP_STYLE_URL`; mặc định Liberty để đường phố dễ đọc |

`.env` là asset bắt buộc, được khai báo trong `pubspec.yaml`. Thiếu file sẽ khiến
khởi động thất bại; tạo từ bản mẫu trước khi chạy. CI tạo `.env` từ `.env.example`
trước các bước kiểm tra. Test mặc định dùng môi trường riêng với `APP_ENV=test`,
không lấy Cloudinary từ máy phát triển; test asset kiểm tra riêng việc đóng gói.

## Cấu hình công khai và thông tin backend

`.env` bị Git bỏ qua; chỉ commit `.env.example` không chứa thông tin riêng của máy.
Tuy nhiên, `.env` được đóng gói trong APK/IPA nên có thể trích xuất. Chỉ đặt cấu hình
client công khai trong file này. Không thêm Cloudinary API Secret, API key backend,
Firebase service account, token hoặc khóa ký. Những giá trị đó thuộc môi trường
backend/secret manager bên ngoài Flutter, kể cả khi backend cũng dùng dotenv.

Unsigned Cloudinary preset cần giới hạn loại ảnh, dung lượng và thư mục ở dịch vụ.
Ký upload và xóa ảnh phải qua backend; cấu hình client không cấp quyền owner/admin.

Bản đồ dùng MapLibre với OpenFreeMap, không dùng `OSM_TILE_URL` và
`OSM_USER_AGENT_PACKAGE_NAME` cũ. Style URL phải là nguồn MapLibre có attribution
phù hợp; style được tải qua mạng, không phải file JSON cấu hình môi trường local.
Luồng hiện tại xem [NATIVE_MAP.md](NATIVE_MAP.md).

Nếu `.env` cũ còn `MAP_DARK_STYLE_URL=https://tiles.openfreemap.org/styles/dark`,
đổi sang `https://tiles.openfreemap.org/styles/liberty` hoặc bỏ biến đó để dùng
cùng nền đường phố tiêu chuẩn. Nền Dark cũ có độ tương phản thấp nên không còn là
lựa chọn mặc định. Sau khi đổi `.env`, chạy lại app đầy đủ để nạp asset mới.

## Firebase native và metadata nền tảng

Giữ `android/app/google-services.json` và
`ios/Runner/GoogleService-Info.plist`: đây là cấu hình native do Firebase SDK dùng,
không phải nguồn cấu hình môi trường của `AppConfig`. App hiện khởi tạo Firebase
native từ các file này, không lặp lại API key Firebase trong `.env`.
Các JSON metadata icon và web manifest cũng giữ nguyên cho công cụ nền tảng.
Web cần bổ sung FirebaseOptions trước khi chạy; xem [BACKEND_SETUP.md](BACKEND_SETUP.md).

Tham khảo API nạp asset: [flutter_dotenv](https://pub.dev/packages/flutter_dotenv).
