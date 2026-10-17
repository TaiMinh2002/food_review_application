# Food Review

Ứng dụng Flutter khám phá quán ăn, viết đánh giá và lưu địa điểm yêu thích.
Base được dựng từ `flutter_food_review_tech_stack.md`, ưu tiên MVP portfolio trong 4–5 tuần.

## Trạng thái hiện tại

- Đã chạy bằng dữ liệu mẫu: danh sách quán, tìm tên không phân biệt hoa/thường, lọc danh mục, chi tiết quán, thêm/bỏ yêu thích.
- Riverpod quản lý dữ liệu/state; go_router điều hướng với bốn tab giữ trạng thái; tab Bản đồ hiện là placeholder; Material 3 theme.
- Có loading, error/retry, empty và trường hợp không tìm thấy địa điểm.
- Auth, review và profile đã có domain/contract hoặc màn hình khởi đầu; **chưa kết nối backend**.
- Yêu thích chỉ lưu trong RAM, mất khi khởi động lại. Quán và tọa độ đều là dữ liệu minh họa.
- Package Firebase, Cloudinary upload (HTTP/image_picker), bản đồ/GPS đã được khai báo; việc cài package chưa có nghĩa tính năng đã tích hợp.

## Chạy dự án

Môi trường đã xác minh: Flutter 3.47.5, Dart 3.13.4. SDK constraint nằm trong `pubspec.yaml`.

```bash
flutter pub get
cp config/app_config.example.json config/app_config.local.json
flutter run --dart-define-from-file=config/app_config.local.json
```

Demo không cần tài khoản Firebase hoặc Cloudinary. Có thể kiểm tra UI trên web:

```bash
flutter run -d chrome
```

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
config/                     # Cấu hình mẫu không chứa secret
docs/                       # Phân tích, kiến trúc, backend, roadmap
test/                       # Kiểm thử hành vi và domain
```

## Tài liệu phát triển

- [Quy tắc phát triển bắt buộc](rule.md) và [hướng dẫn contributor/agent](AGENTS.md)
- [Phân tích stack và phạm vi](docs/PROJECT_ANALYSIS.md)
- [Quy ước kiến trúc](docs/ARCHITECTURE.md)
- [Quản lý cấu hình và dữ liệu nhạy cảm](docs/ENVIRONMENT.md)
- [Thiết kế dữ liệu và cấu hình dịch vụ](docs/BACKEND_SETUP.md)
- [Danh sách đầy đủ các tính năng](docs/FEATURES.md)
- [Backlog, tiêu chí hoàn thành và lộ trình](docs/ROADMAP.md)
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
