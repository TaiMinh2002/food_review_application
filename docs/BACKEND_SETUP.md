# Thiết kế backend và cấu hình tiếp theo

Các mục dưới đây là hướng dẫn triển khai; base hiện chưa kết nối dịch vụ.

## Firebase

1. Application ID Android và bundle ID iOS đã chốt là `com.minhpt.foodreview`.
2. Firebase project đã có ứng dụng Android/iOS tương ứng; hai file cấu hình cùng project
   và khớp application ID/bundle ID.
3. Android dùng `android/app/google-services.json`; Google Services plugin được khai báo
   trong `android/settings.gradle.kts` và áp dụng tại module app.
4. iOS dùng `ios/Runner/GoogleService-Info.plist`; file thuộc Runner target và được chép
   vào app bundle qua Copy Bundle Resources.
5. `main.dart` gọi `await Firebase.initializeApp()` trước `runApp`. Cách cấu hình native
   thủ công này dành cho Android/iOS và không cần `firebase_options.dart`.
6. Bật Authentication email/password, tạo Firestore, rồi thêm FirebaseAuthRepository và
   FirestorePlaceRepository trước khi chuyển provider sang dữ liệu thật.
7. Viết và test rules bằng emulator trước khi deploy; không dùng test mode cho bản phát hành.

Nguồn: https://firebase.google.com/docs/flutter/setup
Cấu hình hiện tại không khởi tạo Firebase Web. Nếu sau này hỗ trợ Web, cần truyền `FirebaseOptions`
cho Web hoặc dùng FlutterFire CLI. Cấu hình client Firebase không phải server secret, nhưng không
commit service-account JSON, private key hoặc credentials admin.

## Schema đề xuất

| Path | Field chính | Quyền dự kiến |
|---|---|---|
| `places/{placeId}` | name, description, address, category, latitude, longitude, imageUrls | Public read, admin write |
| `users/{uid}` | displayName, photoUrl, createdAt | Public read các field hồ sơ, owner cập nhật field cho phép |
| `users/{uid}/favorites/{placeId}` | createdAt | Chỉ owner đọc/ghi |
| `places/{placeId}/reviews/{uid}` | userId, rating, content, imageUrls, createdAt, updatedAt | Public read; owner tạo/sửa/xóa |

ID review bằng uid thực thi đề xuất một review/người/quán. `placeId` có thể lấy từ path;
model domain vẫn giữ placeId. createdAt/updatedAt dùng Firestore Timestamp với server timestamp,
mapper cần xử lý timestamp đang chờ server. Không dùng chuỗi ngày làm dữ liệu chính thức.

Quán mẫu hiện có averageRating/reviewCount để chuẩn bị UI, nhưng không có review giả.
Khi tích hợp, chốt cơ chế aggregate; nếu cache thống kê ở places, chỉ backend được ghi.
Review theo hồ sơ có thể dùng collection-group reviews với userId filter + phân trang;
chỉ tạo index sau khi có query thật và rules tương ứng.

## Checklist rules khi triển khai

- Chặn ghi quán từ client; admin seed qua công cụ đáng tin cậy.
- Owner phải bằng request.auth.uid; không cho đổi userId/createdAt khi update.
- Whitelist keys, kiểm tra rating là integer 1–5, content length, list URL và số ảnh.
- Favorite chỉ owner truy cập, xác minh place tồn tại.
- Hồ sơ không chứa email hoặc thông tin riêng tư trong phần public.
- Test cả unauthenticated, owner và tài khoản khác với emulator.

Repo chưa có rules triển khai để tránh nhầm một policy chưa kiểm thử là đã sẵn sàng.

## Cloudinary

Copy `config/app_config.example.json` thành `config/app_config.local.json` và điền cloud name,
unsigned preset được giới hạn. File mẫu chỉ chuẩn bị public config; chưa có upload service sử dụng.
Quy tắc phân loại cấu hình client và secret server nằm tại `docs/ENVIRONMENT.md`.

```bash
flutter run --dart-define-from-file=config/app_config.local.json
```

Luồng: chọn ảnh → kiểm tra số lượng/loại/dung lượng → HTTP multipart upload → kiểm tra response
→ lưu secure_url vào review. Lưu thêm public_id trong DTO nếu cần quản lý ảnh bằng backend.
AppConfig hiện đọc CLOUDINARY_CLOUD_NAME và CLOUDINARY_UPLOAD_PRESET.
Không đưa API Secret vào dart-define, file JSON hay Dart. Signed upload/delete cần backend xác thực.
Cần xử lý upload thành công nhưng ghi review thất bại (ảnh mồ côi), retry và chống gửi trùng.

## Android/iOS và bản đồ

Base đã khai báo quyền mạng và vị trí foreground trên Android; iOS đã có mô tả quyền
location when-in-use, camera và thư viện ảnh. Khi triển khai luồng sử dụng:

- Android: `INTERNET`, `ACCESS_COARSE_LOCATION` và `ACCESS_FINE_LOCATION` đã có trong
  main manifest. `image_picker` dùng Android Photo Picker/camera intent nên không cần
  quyền đọc toàn bộ thư viện hoặc quyền camera trong manifest.
- iOS: `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription` và
  `NSPhotoLibraryUsageDescription` đã có trong `Info.plist`.
- Chỉ xin quyền khi người dùng bấm “Gần tôi” hoặc chọn ảnh; xử lý denied, deniedForever,
  location service disabled và hủy chọn ảnh. Không cần background location cho MVP.
- flutter_map cần attribution OpenStreetMap, định danh ứng dụng và tile provider phù hợp.
  Đọc chính sách tile hiện hành trước khi bật bản đồ, không prefetch/offline tile công cộng tùy ý.
- Tính khoảng cách bằng latlong2 là khoảng cách địa lý gần đúng, không phải quãng đường lái xe.

Cần kiểm tra tài liệu platform/package đang cài trước khi sửa manifest/Info.plist.
Hạn mức miễn phí và yêu cầu billing cần kiểm tra trực tiếp lúc cấu hình tài khoản;
base không khẳng định chi phí hiện tại.
