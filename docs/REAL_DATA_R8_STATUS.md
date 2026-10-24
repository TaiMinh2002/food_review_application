# R8 — Loại demo khỏi runtime và nghiệm thu toàn app

Cập nhật 24/10/2026. Nghiệm thu tổng thể lộ trình tích hợp dữ liệu thật từ R0 đến R8.

## 1. Trạng thái tích hợp các dịch vụ dữ liệu thật

Toàn bộ các mô-đun nghiệp vụ đã được tích hợp nguồn dữ liệu thật với ngân sách 0 đồng:

| Tính năng / Mô-đun | Nguồn dữ liệu thật (Production) | Fallback / Test Double | Ghi chú & Giới hạn ngân sách 0 |
| --- | --- | --- | --- |
| **Nền bản đồ** | OpenFreeMap vector tiles qua MapLibre | Offline vector tiles | Không tốn phí, không dùng Google Maps API |
| **Quán ăn & Khám phá 5 km** | OpenStreetMap (OSM) trích xuất vùng Phùng Khoang/Hà Nội | Local spatial cache | Bán kính 5 km quanh tâm GPS/thủ công, tìm tiếng Việt không dấu |
| **Chi tiết quán & Chỉ đường** | Dữ liệu OSM + Deep link ứng dụng bản đồ ngoài | DemoPlaceRepository (chỉ khi offline/test) | Không dùng Google Places/Routes API trả phí |
| **Xác thực người dùng** | Firebase Authentication (Email/Password) | Stub / AuthController test | Đăng ký, đăng nhập, quên mật khẩu, phiên bền vững |
| **Hồ sơ công khai** | Cloud Firestore (`users/{uid}`) | Memory profile | displayName, photoUrl, bio, region; bảo mật rules |
| **Yêu thích (Favorites)** | Cloud Firestore (`users/{uid}/favorites/{placeKey}`) | MemoryFavoriteRepository | Realtime stream snapshots, độc lập với Want-to-Visit |
| **Muốn ghé (Want to Visit)** | Cloud Firestore (`users/{uid}/wantToVisit/{placeKey}`) | MemoryWantToVisitRepository | Realtime stream snapshots, độc lập với Favorites |
| **Đánh giá (Reviews)** | Cloud Firestore (`places/{placeKey}/reviews/{uid}`) | DemoReviewRepository (chỉ test) | CRUD theo UID, tránh trùng lặp, server timestamps |
| **Tải ảnh đánh giá** | Cloudinary Unsigned Upload Preset | Mock uploader (test) | Tải ảnh trực tiếp từ thiết bị, không lưu API secret |
| **Thống kê & Feed Reviews** | Firestore Aggregation & collectionGroup | Demo review feed | Tính điểm sao trung bình, phân bố sao, phân trang cursor |
| **Bộ sưu tập (Collections)** | Cloud Firestore (`users/{uid}/collections/{collectionId}`) | DemoCollectionRepository (chỉ test) | Tối đa 50 quán inline, CRUD theo owner, kiểm soát quyền |
| **Báo cáo vi phạm (Reports)** | Cloud Firestore (`reports/{uid}/submissions/{requestId}`) | DemoReportRepository (chỉ test) | Biên nhận báo cáo riêng tư, minh chứng subcollection |
| **Cài đặt & Theme** | SharedPreferences trên thiết bị | Default system theme | Lưu trữ chế độ Sáng / Tối bền vững qua khởi động lại |

## 2. Kiểm tra runtime & Loại bỏ demo

- **Chỉ số `isDemo`**:
  - Tất cả các repository Firestore thật (`FirestoreReviewRepository`, `FirestoreCollectionRepository`, `FirestoreReportRepository`, `FirestoreFavoriteRepository`, `FirestoreWantToVisitRepository`) đều trả về `isDemo: false`.
  - Trên giao diện người dùng, nhãn "Minh họa" chỉ hiển thị khi chạy ở chế độ demo (không có Firebase); khi kết nối Firebase thật, toàn bộ nhãn "Minh họa" được ẩn hoàn toàn và hiển thị nhãn "Quán đã xác minh".
- **Phân tách Provider**:
  - Tất cả các provider (`reviewRepositoryProvider`, `collectionRepositoryProvider`, `reportRepositoryProvider`, `favoriteRepositoryProvider`, `wantToVisitPlacesProvider`) sử dụng cơ chế phát hiện tự động `Firebase.apps.isEmpty`. Khi ứng dụng chạy thực tế với Firebase, các repository Firestore thật luôn được kích hoạt.
  - Các repository Demo (`DemoPlaceRepository`, `DemoReviewRepository`, `DemoCollectionRepository`, `DemoReportRepository`, `MemoryFavoriteRepository`, `MemoryWantToVisitRepository`) được cô lập hoàn toàn thành test doubles cho kiểm thử tự động.

## 3. Kết quả nghiệm thu kỹ thuật (Flutter 3.47.5)

- **Định dạng code (`dart format`)**: 100% tệp nguồn trong `lib/` và `test/` tuân thủ chuẩn định dạng Dart.
- **Phân tích tĩnh (`flutter analyze`)**: **0 issues found** trên toàn bộ dự án.
- **Kiểm thử tự động (`flutter test`)**: **449/449 tests passed** (0 failures, 0 skipped).
- **Bảo mật Firestore Security Rules (`test:rules`)**:
  - Bộ test bảo mật [test/firestore.rules.test.cjs](file:///Volumes/DATA/flutter/food_review_application/test/firestore.rules.test.cjs) kiểm chứng toàn diện các quy tắc phân quyền:
    - Guest chỉ đọc quán active và review public.
    - Owner chỉ sửa review/hồ sơ của chính mình.
    - Favorites, Want-to-Visit, Collections, Reports hoàn toàn riêng tư giữa các tài khoản.
- **Giới hạn số dòng file**: Tất cả các file code đều tuân thủ nghiêm ngặt quy định <= 700 dòng (file lớn nhất `firestore_review_repository.dart` đạt 684 dòng).
