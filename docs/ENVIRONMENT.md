# Quản lý cấu hình và dữ liệu nhạy cảm

## Nguyên tắc

`.env` chỉ dùng cục bộ cho công cụ quản trị hoặc backend đáng tin cậy và đã được
đưa vào `.gitignore`. Không khai báo `.env` trong `pubspec.yaml`: mọi asset đóng
gói trong APK/IPA đều có thể được trích xuất, nên `.gitignore` không bảo vệ secret
sau khi ứng dụng được build.

Flutter client chỉ nhận cấu hình công khai từ `config/app_config.local.json` qua
`--dart-define-from-file`. File local này cũng bị Git bỏ qua. Bản mẫu an toàn để
commit là `config/app_config.example.json`.

## Các nhóm cấu hình

| Biến hoặc file | Nơi sử dụng | Có phải secret? | Cách quản lý |
|---|---|---:|---|
| `APP_ENV` | Flutter client | Không | `config/app_config.local.json` |
| `CLOUDINARY_CLOUD_NAME` | Flutter client | Không | File cấu hình client local |
| `CLOUDINARY_UPLOAD_PRESET` | Flutter client | Không, nhưng phải giới hạn unsigned preset | File cấu hình client local |
| `OSM_TILE_URL` | Flutter client | Không | File cấu hình client local hoặc giá trị mặc định |
| `OSM_USER_AGENT_PACKAGE_NAME` | Flutter client | Không | Giá trị `com.minhpt.foodreview` |
| `CLOUDINARY_API_KEY` | Backend/admin tool | Nhạy cảm | `.env` hoặc secret manager của server |
| `CLOUDINARY_API_SECRET` | Backend/admin tool | Có | `.env` hoặc secret manager của server |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Backend/admin tool | Có quyền quản trị | `.env`; file JSON thực tế phải bị Git bỏ qua |
| `android/app/google-services.json` | Firebase Android client | Cấu hình client | Giữ tại module Android; giới hạn API key trong Google Cloud khi phù hợp |
| `ios/Runner/GoogleService-Info.plist` | Firebase iOS client | Cấu hình client | Giữ trong Runner target và Copy Bundle Resources |

Không đưa Cloudinary API Secret, Firebase service-account JSON, khóa riêng `.pem`,
certificate `.p12`, keystore Android hoặc mật khẩu ký ứng dụng vào Flutter, Dart
define hay repository.

## Thiết lập máy phát triển

Tạo hai file local từ bản mẫu:

```bash
cp .env.example .env
cp config/app_config.example.json config/app_config.local.json
```

Điền Cloudinary cloud name và unsigned upload preset vào
`config/app_config.local.json`, sau đó chạy:

```bash
flutter run --dart-define-from-file=config/app_config.local.json
```

App hiện khởi tạo Firebase Android/iOS từ hai file native, vì vậy không cần
`firebase_options.dart` và không cần lặp lại Firebase API key trong `.env`.

## Trước khi commit hoặc phát hành

- Kiểm tra `.env`, `config/app_config.local.json`, service account và khóa ký đều
  không xuất hiện trong danh sách file chuẩn bị commit.
- Chỉ dùng unsigned Cloudinary preset có giới hạn định dạng, dung lượng, thư mục
  và transformation. Thao tác ký upload hoặc xóa ảnh phải đi qua backend.
- Dùng Firebase Security Rules để bảo vệ dữ liệu. API key Firebase phía client
  không thay thế Authentication, App Check hay Security Rules.
- Đưa secret production vào secret manager của môi trường backend/CI thay vì
  chép vào file trong repository.
