# Food Review

Ứng dụng Flutter khám phá quán ăn, viết đánh giá và lưu địa điểm yêu thích.
Phạm vi MVP và các hướng mở rộng được tổng hợp tại [FEATURES.md](docs/FEATURES.md).

## Trạng thái hiện tại

Dự án đã hoàn tất toàn bộ lộ trình chuyển đổi từ dữ liệu mẫu sang dữ liệu thật (Giai đoạn R0 đến R8) với ngân sách 0 đồng:

- **Bản đồ & Khám phá địa điểm**: Nền bản đồ vector OpenFreeMap hiển thị qua MapLibre; dữ liệu quán ăn thật từ OpenStreetMap (OSM) theo khu vực bán kính 5.000 m; tìm kiếm tiếng Việt không dấu, lọc danh mục ẩm thực, chi tiết quán và chỉ đường mở ứng dụng ngoài.
- **Xác thực (Auth)**: Firebase Authentication (Email & Password), hỗ trợ đăng ký, đăng nhập, quên mật khẩu, cập nhật hồ sơ và duy trì phiên đăng nhập bền vững.
- **Hồ sơ cá nhân & Reviewer**: Lưu trữ hồ sơ công khai tại `users/{uid}`, cập nhật tên, ảnh, tiểu sử, khu vực và thống kê đánh giá thật.
- **Yêu thích & Muốn ghé**: Lưu trữ và đồng bộ thời gian thực độc lập tại `users/{uid}/favorites` và `users/{uid}/wantToVisit`.
- **Đánh giá & Thư viện ảnh**: Viết, chỉnh sửa, xóa đánh giá thật trên Cloud Firestore (`places/{placeKey}/reviews/{uid}`); tải ảnh trực tiếp lên Cloudinary với unsigned preset; tính điểm trung bình và phân bố sao trực tiếp từ Firestore aggregation.
- **Bộ sưu tập cá nhân**: Quản lý bộ sưu tập tại `users/{uid}/collections/{collectionId}` với số lượng tối đa 50 địa điểm inline, phân quyền nghiêm ngặt theo chủ sở hữu.
- **Báo cáo vi phạm**: Gửi và lưu trữ biên nhận báo cáo tại `reports/{uid}/submissions/{requestId}` kèm minh chứng ảnh riêng tư.
- **Cài đặt & Giao diện**: SharedPreferences lưu trữ cài đặt Theme (Sáng / Tối / Theo hệ thống) bền vững trên thiết bị.
- **Bảo mật**: Bộ quy tắc bảo mật Cloud Firestore (`firestore.rules`) đã được thiết lập nghiêm ngặt và kiểm chứng 100% qua bộ kiểm thử unit testing.

Chi tiết tiến độ từng giai đoạn được ghi nhận tại các tài liệu:
- [Kế hoạch tích hợp dữ liệu thật](docs/REAL_DATA_INTEGRATION_PLAN.md)
- [R0 — Hợp đồng dữ liệu & Rules](docs/REAL_DATA_R0_STATUS.md)
- [R1 — Bản đồ & OSM 5 km](docs/REAL_DATA_R1_STATUS.md)
- [R2 — Khám phá & Danh mục](docs/REAL_DATA_R2_STATUS.md)
- [R3 — Auth & Cài đặt](docs/REAL_DATA_R3_STATUS.md)
- [R4 — Reviews & Cloudinary](docs/REAL_DATA_R4_STATUS.md)
- [R5 — Favorites & Muốn ghé](docs/REAL_DATA_R5_STATUS.md)
- [R6 — Collections & Public Reviewer](docs/REAL_DATA_R6_STATUS.md)
- [R7 — Báo cáo vi phạm](docs/REAL_DATA_R7_STATUS.md)
- [R8 — Nghiệm thu & Loại bỏ demo](docs/REAL_DATA_R8_STATUS.md)

## Chạy dự án

Môi trường đã xác minh: Flutter 3.47.5, Dart 3.13.4. SDK constraint nằm trong `pubspec.yaml`.

```bash
cp .env.example .env
flutter pub get
flutter run
```

App nạp `.env` bằng `flutter_dotenv` trước khi khởi tạo Firebase. File này đã được
Git bỏ qua và chỉ chứa cấu hình client công khai; xem [ENVIRONMENT.md](docs/ENVIRONMENT.md).
Máy hiện tại đã có `.env` thì không cần chép lại từ bản mẫu.

## Kiểm tra

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Commit `pubspec.lock` để giữ dependency đã resolve. CI chạy format, analyze, test khi đưa lên GitHub.

## Cấu trúc

```text
lib/
  main.dart                 # Entry point, ProviderScope
  app/                      # Root app, navigation shell
  core/
    config/                 # Public client configuration
    errors/                 # Application exception
    router/                 # go_router, lifecycle
    theme/                  # Material theme
  features/
    auth/                   # Auth contract, màn hình khởi đầu
    places/                 # Domain, demo repository, provider, UI
    reviews/                # Review model, repository contract
    favorites/              # Repository RAM, notifier, UI
    profile/                # User model, màn hình khởi đầu
  shared/widgets/           # Trạng thái dùng chung
.env.example                # Mẫu cấu hình client, đọc bằng flutter_dotenv
docs/                       # Tính năng, kiến trúc, backend, kế hoạch UI
test/                       # Kiểm thử hành vi và domain
```

## Tài liệu phát triển

- [Quy tắc phát triển bắt buộc](rule.md) và [hướng dẫn contributor/agent](AGENTS.md)
- [Quy ước kiến trúc](docs/ARCHITECTURE.md)
- [Quản lý cấu hình và dữ liệu nhạy cảm](docs/ENVIRONMENT.md)
- [Thiết kế dữ liệu và cấu hình dịch vụ](docs/BACKEND_SETUP.md)
- [Tính năng chính, mở rộng và lộ trình](docs/FEATURES.md)
- [Đặc tả luồng và routing](docs/food_review_luong_hoat_dong_routing.md)
- [Kế hoạch UI theo từng task](docs/UI_IMPLEMENTATION_PLAN.md)
- [Nền thiết kế, dữ liệu và routing T01–T02](docs/UI_FOUNDATION.md)

Nguồn API tham khảo: [Riverpod](https://riverpod.dev/docs/concepts2/providers),
[go_router](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html),
[Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup).

## Portfolio

Sau khi hoàn thiện MVP: bổ sung ảnh chụp thật Android/iOS, video luồng đăng review,
thiết bị đã kiểm thử và đường dẫn repository. Chưa có screenshot hay release ở giai đoạn base.

## Design system

Core UI dùng chung theo Stitch: [hướng dẫn, tokens và component API](docs/DESIGN_SYSTEM.md).
Mở tab **Hồ sơ → Xem UI Kit** để xem các component, hoặc chọn giao diện **Sáng / Tối / Theo hệ thống**.
