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
T10/T11/T12 đã có adapter Auth email/password/session/logout/register/reset password; T13/T14 đã nối form và quản lý review với contract demo; Firestore vẫn chưa tích hợp.
Web cần FirebaseOptions riêng. Xem [LOGIN_AUTH_UI.md](LOGIN_AUTH_UI.md).
Không thêm code generation, service locator hoặc base repository tổng quát khi chưa cần.
Phạm vi/trạng thái/lộ trình ở [FEATURES.md](FEATURES.md); schema, query và phân quyền ở
[BACKEND_SETUP.md](BACKEND_SETUP.md).

## Dependency injection

`ProviderScope` ở main; `placeRepositoryProvider` đang cấp `DemoPlaceRepository`.
Khi có Firestore, thêm implementation mới ở places/data và đổi provider.
Không tạo Firestore instance trong widget. Test có thể override provider mà không kết nối mạng.
Search dùng capability `PlaceSearchRepository.searchPlaces(request, cursor, pageSize)`
qua `placeSearchRepositoryProvider`; nguồn mặc định tái sử dụng DemoPlaceRepository.
Backend implementation phải áp dụng query/limit/cursor, không tải cả feed để lọc ở UI.
`searchControllerProvider` autoDispose theo từng route, debounce và bỏ stale response;
form T06 giữ draft riêng, metadata qua query giới hạn một item. Lịch sử chỉ lưu trong phiên.
T07 tái sử dụng controller/result slivers của Search. `PlaceCategory` định nghĩa ID/taxonomy;
`PlaceSearchRequest.categoryScope` là ràng buộc gốc AND với các bộ lọc khác trước count/paging.
Controller của route giữ scope từ seed kể cả Apply/Reset; form T06 chỉ hiển thị món con
trong scope, Reset vẫn giữ danh mục. Xem [CATEGORY_UI.md](CATEGORY_UI.md).
Map dùng capability `PlaceMapRepository.findInViewport(bounds, filters, near, limit)`;
`placeMapControllerProvider` giữ query/result/GPS và chặn stale response, screen giữ camera.
`UserLocationRepository` có implementation Geolocator với foreground fix theo thao tác người dùng;
không đọc GPS trong build. Xem [MAP_UI.md](MAP_UI.md).
`reviewRepositoryProvider` cấp `DemoReviewRepository`; `reviewPreviewProvider(placeId)`
đọc tối đa hai review qua contract `watchForPlace(placeId, limit: 2)`, có lỗi/retry riêng.
T09a dùng capability `ReviewFeedRepository` từ cùng nguồn inject: summary toàn quán,
filter/sort và cursor paging. `reviewFeedControllerProvider` giữ state theo route/quán,
retry độc lập, chặn stale response và dữ liệu sai quán; không tải toàn backend để lọc.
Preview và All Reviews dùng chung `RestaurantReviewCard`. T13/T14 dùng `ReviewRepository` và
`ReviewManagementRepository`; owner check được áp dụng ở adapter demo và phải được lặp lại trong
Firestore rules.
Xem [ALL_REVIEWS_UI.md](ALL_REVIEWS_UI.md).

T09b dùng `galleryRepositoryProvider` ghép media snapshot của Place và exact review
lookup qua `ReviewMediaRepository`. Không quét toàn bộ review hay thay nguồn inject
bằng demo ngầm. `galleryProvider(request)` autoDispose theo quán/nguồn, kiểm tra quán
trước khi đọc ảnh; screen giữ filter/scroll và dialog giữ PageController/zoom.
Xem [GALLERY_UI.md](GALLERY_UI.md).

`FavoriteRepository` dùng stream `watchPlaceIds(userId)` và async
`setFavorite(userId, placeId, value)`. `favoriteIdsProvider` giữ state theo session,
cập nhật lạc quan, hoàn tác khi ghi lỗi và reset khi đăng xuất. Implementation hiện tại
là RAM demo; khi nối Firestore chỉ thay implementation/provider ở tầng data.
Không gọi Firestore trực tiếp trong widget. T10 gate thao tác favorite theo session user ID;
login không tự toggle favorite. `authSessionProvider` giữ loading/error/guest/user;
controller sign-in/out gọi AuthRepository, UI không gọi Firebase trực tiếp.
`WantToVisitRepository` dùng contract stream/async tương tự nhưng có provider và adapter
riêng; thao tác want-to-visit không bao giờ tự xóa favorite.

## Routing

- `/search`: Search T05 với query/filter/sort/phân trang riêng; `/search/filters`: form nháp T06, Apply/Reset/Cancel. Xem [SEARCH_UI.md](SEARCH_UI.md).
- `/home`: Home theo Stitch (T03), giữ tìm/lọc demo tại chỗ và cuộn khi chuyển tab.
- `/categories/:categoryId`: T07 trong branch Home, giữ thanh bốn tab; Home có lối “Xem danh mục”. ID sai không gọi query. Detail push trên root và Back giữ bộ lọc/vị trí cuộn của danh mục.
- `/restaurants/:restaurantId`: chi tiết Stitch T04 với gallery, menu, review preview và thanh giá/chỉ đường; map ID sang `placeId` trong domain, xử lý ID không tồn tại. Xem [RESTAURANT_DETAIL_UI.md](RESTAURANT_DETAIL_UI.md).
- `/map`: T08 dùng flutter_map/OSM, marker và card quán; `restaurantId` chọn quán từ chi tiết. Camera/selection giữ trong indexed stack. Xem [MAP_UI.md](MAP_UI.md).
- `/restaurants/:restaurantId/gallery`: T09b trên root; `index` mở viewer, `source=review&reviewId=...` chọn ảnh review đúng scope. Đóng viewer về lưới, Back về nguồn. Xem [GALLERY_UI.md](GALLERY_UI.md).
- `/favorites`: T15 hiển thị quán đã lưu theo phiên, có tìm kiếm/lọc/sắp xếp và trạng thái
  loading/error/empty; xem [FAVORITES_UI.md](FAVORITES_UI.md).
- `/want-to-visit`: T16 danh sách độc lập theo phiên, có tìm/sort, bookmark từ Detail,
  loading/error/empty; xem [WANT_TO_VISIT_UI.md](WANT_TO_VISIT_UI.md).
- `/profile`: trang khởi đầu hồ sơ.
- `/profile`: T17 My Profile theo session, guest/user variant, các lối vào danh mục và
  trạng thái loading/error; số liệu chưa có contract hiển thị `—`. Xem [MY_PROFILE_UI.md](MY_PROFILE_UI.md).
- `/login`: T10 theo Stitch 13; email/password, validation/loading/error, returnTo và links T11/T12. Xem [LOGIN_AUTH_UI.md](LOGIN_AUTH_UI.md).
- `/register`: T11 theo Stitch 14; tạo Firebase Auth account, displayName, validation/loading/error và giữ returnTo/action. Xem [REGISTER_AUTH_UI.md](REGISTER_AUTH_UI.md).
- `/forgot-password`: T12 theo Stitch 15; email, reset password, trạng thái gửi chung, retry và quay về Login. Xem [FORGOT_PASSWORD_UI.md](FORGOT_PASSWORD_UI.md).
- `/restaurants/:restaurantId/reviews/create`: T13 theo Stitch Write Review; auth guard, form review và submit qua `ReviewRepository`. Xem [WRITE_REVIEW_UI.md](WRITE_REVIEW_UI.md).
- `/my-reviews`: T14 theo Stitch 18 - My Reviews; stream review theo user, edit qua form T13 và delete có xác nhận. Xem [MY_REVIEWS_UI.md](MY_REVIEWS_UI.md).
- `/reviews/:reviewId/edit?restaurantId=...`: T14 lookup theo cặp `(restaurantId, reviewId)`, kiểm tra owner và cập nhật qua `ReviewManagementRepository`.

Bốn tab dùng indexed stack giữ search/filter khi chuyển tab. Router thuộc provider và được dispose.
`AppRoute` định nghĩa route có tên và helper encode tham số. URL `/places`, `/places/:placeId`,
`/sign-in` cũ redirect về canonical route và giữ query. Detail được push trên root navigator;
Back pop về nguồn, direct link không có history thì về Home. Các route chưa có feature dùng
placeholder có task ID; admin bị từ chối mặc định. Xem [UI_FOUNDATION.md](UI_FOUNDATION.md).
T10 đã có auth refresh/redirect và AuthGate cho các route riêng; khách vẫn xem quán,
Profile/Favorites hiện lời mời đăng nhập. Giữ đích sau login và không tự thực hiện hành động;
session loading/error không hiển thị private content kể cả snapshot cũ. Router không bị
tạo lại khi session đổi. Admin vẫn từ chối mặc định, chưa có role backend.

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
