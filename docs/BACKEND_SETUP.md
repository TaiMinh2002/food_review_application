# Food Review — Thiết kế backend và cấu hình dịch vụ

Phạm vi sản phẩm nằm tại [FEATURES.md](FEATURES.md). Tài liệu này mô tả thiết kế dữ liệu
và hướng tích hợp tương ứng, **chưa phải backend đã triển khai hoặc rules đã kiểm thử**.

## 1. Hiện trạng và cấu hình Firebase

- Application ID Android/bundle ID iOS: `com.minhpt.foodreview`.
- Android dùng `android/app/google-services.json` và Google Services plugin;
  iOS dùng `ios/Runner/GoogleService-Info.plist` thuộc Runner/Copy Bundle Resources.
- `lib/main.dart` đã gọi `Firebase.initializeApp()` trước `runApp`. Khởi tạo native
  không đồng nghĩa đã có Auth/Firestore repository; provider quán vẫn dùng demo.
- Web chưa có `FirebaseOptions`; cần cấu hình riêng trước khi chạy Web.
- Khi tích hợp: bật email/password, tạo Firestore, tách development/production,
  triển khai repository qua Riverpod; seed quán bằng admin tool ngoài app.
- Cấu hình công khai/secret theo [ENVIRONMENT.md](ENVIRONMENT.md).
  Không đặt service account, Cloudinary API Secret hoặc khóa ký trong Flutter.

## 2. Schema đề xuất theo phạm vi

Các collection mở rộng chỉ tạo khi làm feature tương ứng. Timestamp dùng server timestamp;
mapper xử lý giá trị đang chờ server, domain dùng `DateTime`, không phụ thuộc Firebase SDK.

| Path | Trường chính dự kiến | Quyền |
| --- | --- | --- |
| `places/{placeId}` | name, normalizedName, description, address, categoryId, latitude, longitude, imageUrls, status, averageRating, reviewCount | Guest đọc quán hiển thị; backend/admin tool ghi |
| `users/{uid}` | displayName, photoUrl, createdAt, updatedAt, status | Guest đọc hồ sơ hiển thị; owner chỉ sửa tên/avatar, backend quản lý status |
| `users/{uid}/private/profile` | settings và dữ liệu riêng nếu cần; email ưu tiên đọc từ Firebase Auth | Chỉ owner; không để email/role trong hồ sơ public |
| `places/{placeId}/reviews/{uid}` | placeId, userId, rating, content, images, status, createdAt, updatedAt | Guest đọc bài hiển thị; owner tạo/sửa/xóa nội dung của mình, backend quản lý moderation |
| `users/{uid}/favorites/{placeId}` | createdAt | Chỉ owner; MVP |
| `users/{uid}/wantToVisit/{placeId}` | createdAt | Chỉ owner; T16 |
| `users/{uid}/collections/{collectionId}` | name, description, createdAt, updatedAt | Chỉ owner; T21–T22, mặc định riêng tư |
| `users/{uid}/collections/{collectionId}/places/{placeId}` | addedAt | Chỉ owner, không trùng quán trong collection |
| `users/{uid}/notifications/{notificationId}` | type, targetType, targetIds, createdAt, readAt | Backend tạo; recipient đọc và chỉ cập nhật readAt; T23 |
| `reports/{reportId}` | reporterId, targetType, targetIds, reason, description, evidence, status, createdAt, updatedAt, version | T25–T27: user đã đăng nhập gửi qua backend; admin đọc/xử lý qua backend |
| `reports/{reportId}/actions/{actionId}` | actorId, action, fromStatus, toStatus, note, createdAt | Backend ghi lịch sử bất biến; chỉ admin đọc |

Favorite, muốn ghé và membership collection là ba tập độc lập. Xóa collection cần dọn
subcollection bằng backend; không giả định xóa document cha tự xóa các document con.
Các số đếm/thumbnail dẫn xuất phải có nguồn và cơ chế cập nhật rõ ràng.

Giá, giờ mở cửa theo múi giờ/ngày nghỉ, menu/liên hệ/tiện ích, geohash, tiêu chí đánh giá,
helpful/follow/comment, thiết bị nhận push và dữ liệu kinh doanh chưa thuộc schema bắt buộc.
Bổ sung cùng feature mở rộng, migration và rules tương ứng; không tạo sẵn collection rỗng
cho toàn bộ ý tưởng P1–P5. Không dùng OSM làm nguồn mặc định cho menu/review/danh sách quán.

## 3. Review, định danh và thống kê

T09a đã có capability `ReviewFeedRepository` (xem [ALL_REVIEWS_UI.md](ALL_REVIEWS_UI.md)).
Khi nối Firestore, query theo quán + trạng thái hiển thị, lọc sao/có ảnh và sort ổn định
trước cursor/limit; count phải phản ánh toàn bộ kết quả lọc. Summary/histogram/số bài
có ảnh là aggregate toàn bộ review hiển thị của quán, không chỉ page đã tải.
Thiếu histogram thì trả null; không suy phân bố từ average. Chuẩn bị index tương ứng
và cập nhật aggregate khi tạo/sửa/xóa/moderate; fixture Place và Review hiện còn độc lập.

- Giữ thiết kế một review/người/quán: document ID là UID, `userId` bằng UID đăng nhập,
  `placeId` bằng ID quán trong path. Hai trường này và `createdAt` bất biến khi update.
- UID không phải review ID duy nhất toàn app. Đề xuất cho T14: route edit giữ
  `/reviews/:reviewId/edit` và bắt buộc query `restaurantId`; repository lookup bằng
  `(placeId, reviewId)`. Report/notification nhắm review cũng mang cả hai ID.
  Cần nối validation/helper/router/test khi triển khai; placeholder hiện chưa áp dụng contract này.
- Một review có rating integer 1–5, nội dung không rỗng sau trim. Giới hạn độ dài/số ảnh,
  dung lượng và định dạng cần chốt trước T13; tham khảo 10–2.000 ký tự và tối đa 3 ảnh,
  chưa coi đây là validation đã có trong model hiện tại.
- `images` là metadata DTO gồm `secureUrl`, `publicId` để quản lý media;
  mapper cấp `imageUrls` cho domain hiện tại, không đưa chi tiết Cloudinary vào UI.
- Backend tính `averageRating`, `reviewCount` từ review hiển thị khi tạo/sửa/xóa/ẩn/khôi phục;
  không cho client tự ghi aggregate. Xử lý sự kiện lặp hoặc sai thứ tự phải tránh cộng trùng;
  có cách tính lại để đối soát. Điểm demo không chứng minh có review thật.
- Tên/avatar người viết lấy từ hồ sơ public hiện hành, có fallback khi hồ sơ không còn hiển thị;
  không để chủ review tự giả danh tài khoản khác qua snapshot tên/avatar tùy ý.

## 4. Query, repository và phân trang

Giữ hướng Screen → Provider → Repository contract → Data implementation → SDK/HTTP.

- Auth: triển khai email/password, auth stream, reset password và tạo profile có retry;
  không đăng ký lại account khi chỉ bước ghi profile thất bại.
- Place/Search: query theo danh mục, status và sort; chuẩn hóa tên khi seed/cập nhật,
  dùng cursor/phân trang. Tìm không dấu, toàn văn và gần tôi cần chiến lược query riêng;
  không lọc cục bộ một trang rồi coi đó là kết quả toàn bộ dữ liệu.
- Review: mở rộng contract đọc theo cặp ID, phân trang theo quán, my reviews theo `userId`,
  update/delete; collection-group query cần bảo đảm `placeId`/`userId` và quyền tương ứng.
- Favorite: đổi contract RAM đồng bộ thành stream/async theo user; lỗi ghi có rollback,
  reset subscription/cache theo phiên. Want-to-visit/collection dùng contract riêng.
- Profile/notification/report: tách public/private, phân trang inbox/admin list,
  chỉ nhận target type và IDs được hỗ trợ, không nhận URL tùy ý để điều hướng.
- Tạo index theo query thực tế (status/category/sort, userId/time, report status/time…)
  và version-control cấu hình khi tích hợp; repo hiện chưa có rules/index triển khai.

## 5. Báo cáo, moderation và quyền

T25–T27 cần backend đáng tin cậy, chẳng hạn Cloud Functions hoặc API tương đương;
chưa có implementation trong repo. Backend xác minh Firebase identity và quyền admin
bằng claim do server cấp hoặc nguồn quyền chỉ server quản lý; không tin role từ form.

- Gửi report: kiểm tra người gửi, target tồn tại, reason hợp lệ và giới hạn minh chứng;
  dùng request ID ổn định cho retry, giới hạn tốc độ. Client không tự đặt trạng thái xử lý.
- Target gồm `place` + placeId, `review` + placeId/reviewId, hoặc `user` + userId;
  report ID chỉ là định danh báo cáo, không thay định danh nội dung bị báo cáo.
- Trạng thái dự kiến: `pending → inReview → resolved/rejected`. Khi triển khai phải chốt
  hành động hợp lệ cho từng target; ẩn nội dung là soft hide, không xóa vĩnh viễn mặc định.
- Cập nhật moderation kiểm tra version/trạng thái hiện tại để tránh hai admin ghi đè;
  ghi actor/time/action/audit cùng thay đổi liên quan trong transaction khi phù hợp.
- Backend tạo inbox từ sự kiện được hỗ trợ, ví dụ kết quả xử lý báo cáo; retry không tạo
  thông báo trùng. Inbox không mặc nhiên có push hoặc follow/comment notifications.
- Chỉ công khai nội dung có trạng thái được phép; query phải phù hợp rules.
  Minh chứng, lý do nội bộ và dữ liệu người báo cáo không được public.

Checklist rules/emulator trước deploy:

- Guest chỉ đọc dữ liệu công khai; account A không đọc/ghi private data của B.
- Whitelist fields, type/length/rating/URL/số ảnh; kiểm tra quán và owner;
  chặn sửa role/status/aggregate, userId/placeId/createdAt từ client.
- Collection membership kiểm tra parent/owner; notification chỉ cho sửa readAt;
  client không trực tiếp ghi report status, audit hoặc tạo inbox.
- Test cả query/list/get/write, guest/owner/user khác/admin, nội dung ẩn và ID sai.
  Backend dùng quyền admin cũng phải validate dữ liệu/quyền vì không dựa vào client rules.

## 6. Cloudinary và quy trình ảnh

Copy `config/app_config.example.json` thành `config/app_config.local.json`; AppConfig hiện
đọc `CLOUDINARY_CLOUD_NAME` và `CLOUDINARY_UPLOAD_PRESET`, chưa có upload service.

```bash
flutter run --dart-define-from-file=config/app_config.local.json
```

Luồng dự kiến: chọn ảnh → kiểm tra số lượng/loại/dung lượng → upload → giữ metadata
→ lưu review/avatar/minh chứng. Lỗi upload và lỗi ghi dữ liệu xử lý riêng; giữ draft,
URL đã upload và request ID để retry không tạo bản ghi/ảnh trùng.
Unsigned preset phải bị giới hạn; kiểm tra client không thay thế kiểm soát phía dịch vụ/backend.
Nếu cần ràng buộc ảnh theo owner hoặc kiểm soát lạm dụng chặt hơn, dùng signed upload qua backend.
Xóa ảnh/ký upload chỉ qua backend, xác minh owner và ảnh còn được tham chiếu trước khi xóa;
có cơ chế dọn ảnh mồ côi. Không đưa API Secret vào Dart/JSON client/dart-define.

## 7. Native, bản đồ và nghiệm thu

T08 hiện đã có UI/logic Map và adapter Geolocator; bằng chứng/giới hạn ở [MAP_UI.md](MAP_UI.md).
Khi thay nguồn demo, PlaceRepository cần implement thêm `PlaceMapRepository.findInViewport`:
lọc bounds và tọa độ hợp lệ, áp dụng điều kiện Search/radius/limit ở server,
trả `hasMore` và cờ demo trung thực; cần spatial index hoặc dịch vụ truy vấn địa lý phù hợp.
Không dùng `fetchPlaces` tải toàn collection để lọc vùng ở widget.

- Android đã có INTERNET và quyền vị trí foreground; iOS có mô tả location when-in-use,
  camera và thư viện ảnh. Kiểm tra cấu hình theo package/platform trước khi tích hợp picker.
- Chỉ xin quyền khi người dùng cần GPS/chọn ảnh; xử lý denied/deniedForever,
  dịch vụ vị trí tắt và hủy chọn ảnh; không theo dõi vị trí nền trong MVP.
- `flutter_map` dùng attribution, định danh ứng dụng và tile provider phù hợp;
  kiểm tra chính sách tile trước khi bật, không tùy ý tải trước tile công cộng.
- Khoảng cách địa lý gần đúng không phải quãng đường lái xe; mở ứng dụng ngoài để chỉ đường.
- Nghiệm thu cùng feature: đăng nhập/đổi tài khoản, dữ liệu sau restart, quyền, mạng lỗi,
  upload một phần, aggregate và thao tác admin đồng thời; test native Android/iOS khi có thiết bị.
- Kiểm tra quota/billing/chính sách hiện hành khi cấu hình, không mặc định dịch vụ miễn phí.
  Xóa tài khoản sau này cần quy trình xử lý Auth/private data/review/media và audit, tách khỏi logout.

Tài liệu dịch vụ để đối chiếu lúc tích hợp:
[Firebase Flutter setup](https://firebase.google.com/docs/flutter/setup),
[Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started),
[Cloudinary upload](https://cloudinary.com/documentation/upload_images),
[OSM tile policy](https://operations.osmfoundation.org/policies/tiles/).

## Search T05–T06: contract hiện có

T07 mở rộng cùng contract bằng `PlaceSearchRequest.categoryScope` (ID ổn định).
Backend phải áp dụng **root scope AND bộ lọc món con/query/giá/điểm/tiện ích** trước
sort/count/limit/cursor. Có thể lưu category IDs/ancestor IDs đã chuẩn hóa để query theo
taxonomy `PlaceCategory`; không coi root và món con là một tập OR hoặc lọc bù sau paging.
ID không tồn tại cần lỗi an toàn. Demo minh họa cách kết hợp, chưa phải Firestore index/query.

UI/demo đã dùng PlaceSearchRepository.searchPlaces(request, cursor, pageSize).
Khi thay DemoPlaceRepository, implement capability này hoặc override
placeSearchRepositoryProvider cùng nguồn dữ liệu. Backend phải áp dụng category
OR, tiện ích AND, minRating, giá giao khoảng, sort và limit, tie-break theo ID;
trả cursor ổn định cho đúng query. Offset cursor của demo không phải Firestore cursor.
PlaceSearchPage còn cung cấp taxonomy/tiện ích để form không quét toàn bộ quán.
Tên quán và tên món cần chỉ mục/tìm kiếm chuẩn hóa tiếng Việt; nếu Firestore
không đáp ứng query kết hợp/toàn văn thì dùng API tìm kiếm phù hợp, không tải
cả collection về widget. Search/form T06 chưa bật distance/open-now vì thiếu dữ liệu có nguồn;
Map T08 có GPS foreground và chip bán kính riêng, không suy ra giờ mở cửa.
Chi tiết và giới hạn hiện tại: [SEARCH_UI.md](SEARCH_UI.md).
