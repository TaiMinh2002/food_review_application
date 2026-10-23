# Kế hoạch thay dữ liệu demo bằng dữ liệu thật

Ngày lập: 22/10/2026. Phạm vi: toàn bộ tính năng người dùng hiện có trên Android/iOS.
Đây là kế hoạch, không phải bằng chứng tích hợp hoặc deploy. Trạng thái R0 và đầu R1
được ghi trong [REAL_DATA_R0_STATUS.md](REAL_DATA_R0_STATUS.md); phần Map/Home/gói OSM của
R1 được ghi trong [REAL_DATA_R1_STATUS.md](REAL_DATA_R1_STATUS.md). Các đợt còn lại
chưa triển khai.
Web là hạng mục riêng nếu được chọn; không coi Web chạy được chỉ vì widget tests pass.

## 1. Mục tiêu và ràng buộc

- Ngân sách dịch vụ bằng 0; không Google Maps/Places key, không bật billing/Blaze,
  không Cloud Functions/Cloud Run hoặc dịch vụ đòi phương thức thanh toán.
- Giữ Firebase Auth, Firestore Spark, Cloudinary Free trong hạn mức tài khoản thực tế;
  kiểm tra gói/quota trước sử dụng. Hết quota thì báo lỗi/giới hạn, không nâng gói.
- Giữ MapLibre/OpenFreeMap. Quán đến từ OSM thật; mặc định khám phá trong bán kính
  5.000 m quanh GPS hoặc tâm được người dùng chọn. Không nhập quán giả vào Firestore.
- Review, ảnh, số đếm của app xuất phát từ dữ liệu đã lưu; không dùng rating/ảnh demo
  lấp chỗ trống. Không đủ dữ liệu thì hiện trạng thái thiếu hoặc chưa có đánh giá.
- Không triển khai Notifications hoặc giao diện admin đã bị loại khỏi phạm vi.
  Công cụ bảo trì chạy thủ công tại máy phát triển có thể cần cho dữ liệu/ảnh.
- Giữ Screen → Provider → Repository → SDK/HTTP. Thay contract khi nguồn thật
  không đáp ứng semantics demo, không cố giữ API khiến kết quả bị sai.

## 2. Nguồn dữ liệu cho toàn ứng dụng

| Nhóm/màn | Nguồn thật | Cách xử lý dữ liệu thiếu |
| --- | --- | --- |
| Nền Map | OpenFreeMap qua MapLibre hiện có | Lỗi mạng/retry, không dựng nền giả |
| Home, Map, Search, Category, bộ chọn quán | POI OSM theo vùng/bán kính | Nêu phạm vi và ngày dữ liệu, không hứa đầy đủ mọi quán |
| Chi tiết quán | OSM theo ID + cache/gói khu vực | Không bịa địa chỉ, giờ mở cửa, món, giá hoặc tiện ích |
| Rating, review preview, All Reviews | Firestore review public | Không có review thì không có điểm |
| Gallery | Ảnh review public đã lưu; ảnh OSM chỉ dùng khi xác minh quyền nguồn | Empty state, không ảnh stock giả làm ảnh quán |
| Login/Register/Forgot Password | Firebase Auth email/password | Thông báo thật, không giả gửi email thành công |
| Profile/Edit Profile/Public Reviewer | Auth identity + hồ sơ public Firestore | Trường không hỗ trợ được ẩn hoặc ghi rõ |
| My Reviews | Query review theo UID | Phân trang, filter và summary đúng toàn bộ query |
| Favorites/Muốn ghé | Hai tập Firestore riêng theo UID | Quán mất khỏi nguồn vẫn có trạng thái không còn khả dụng |
| Collections/Editor | Firestore theo owner | Membership độc lập với hai danh sách trên |
| Report | Firestore private + minh chứng private theo thiết kế đợt R7 | Không gửi ảnh công khai hoặc báo thành công khi chỉ lưu RAM |
| Settings | Lưu theme tại thiết bị; logout/reset password qua Auth | Không tạo nội dung support/privacy giả |

## 3. Kiến trúc khám phá miễn phí và giới hạn

Tách nền bản đồ, danh mục POI và nội dung cộng đồng thành ba nguồn độc lập.
Không dùng Firestore để tải toàn bộ quán rồi lọc bán kính trong widget.

**Phát triển/kiểm chứng:** Overpass tìm restaurant/cafe/fast_food/food_court
theo vùng giới hạn, với timeout, một request đang chạy cho cùng query, cache và
backoff khi 429/504. Không tự retry liên tục hoặc đổi endpoint để vượt hạn mức.
Tài liệu nhà vận hành cảnh báo không dùng public instance làm backend đại chúng;
cache không biến public instance thành dịch vụ production được bảo đảm.

**Phát hành ngân sách 0:** mặc định chuẩn bị gói POI OSM khu vực từ extract hợp lệ,
truy vấn spatial index trên thiết bị. Có manifest vùng, phiên bản, thời điểm trích xuất,
nguồn, giấy phép và checksum. Ban đầu hỗ trợ khu vực đã kiểm chứng; ngoài vùng thì
thông báo chưa hỗ trợ, không trả demo và không gọi public Overpass ngầm.
Pipeline tạo gói chạy trên máy phát triển, không cần server trả phí. Đo kích thước
trước khi chọn asset đóng gói hay tải từ nơi phân phối miễn phí có điều kiện phù hợp.

Local query ở repository trên gói khu vực có index là kiến trúc dự kiến cho nguồn này;
khác với tải toàn bộ collection backend hoặc lọc một page trong widget. Cần cập nhật
ARCHITECTURE/rule về query local có giới hạn khi triển khai R1, kèm đo hiệu năng.

- ID chuẩn dạng `osm_node_123`, `osm_way_456`, `osm_relation_789`; luôn giữ source/type/id.
  ID OSM có thể bị xóa/thay đổi; không hứa ổn định vĩnh viễn hoặc gộp theo tên đơn thuần.
- Point cho way/relation phải có quy tắc nhất quán; kiểm tra khoảng cách tới điểm đại diện
  sau query, ghi rõ khoảng cách đường chim bay, không giả khoảng cách đi bộ.
- Home/Search/Category/Map dùng chung search context: tâm, bán kính, dataset version.
  Cursor gắn với context + filter + sort; đổi context thì reset kết quả/cursor.
- Không nói tìm toàn quốc khi chỉ tìm vùng 5 km. GPS bị từ chối cho chọn tâm thủ công.
- Filter giá/menu/open-now chỉ bật khi có dữ liệu đáng tin. OSM cuisine không map được
  thì giữ chưa phân loại, không suy đoán món từ tên quán.
- Giữ attribution OSM/OpenFreeMap và điều kiện ODbL cho gói dữ liệu phân phối.

## 4. Thiết kế Firestore dự kiến cần chốt ở R0

| Path | Vai trò và quyền |
| --- | --- |
| `places/{placeKey}` | Tham chiếu OSM được công cụ tin cậy đăng ký từ cùng dataset; guest đọc, client không sửa catalog/aggregate |
| `places/{placeKey}/reviews/{uid}` | Một review/người/quán; owner sửa nội dung, guest chỉ đọc public |
| `users/{uid}` | Hồ sơ public: tên, ảnh, bio/khu vực nếu hỗ trợ; không email/role |
| `users/{uid}/private/profile` | Cài đặt riêng nếu cần; chỉ owner |
| `users/{uid}/favorites/{placeKey}` | Owner đọc/ghi, timestamp thật |
| `users/{uid}/wantToVisit/{placeKey}` | Owner đọc/ghi; không ảnh hưởng favorite |
| `users/{uid}/collections/{collectionId}` | Owner; đề xuất lưu tối đa 50 place IDs ngay trong doc để update/delete nguyên tử |
| `reports/{uid}/submissions/{requestId}` | Reporter tạo/đọc receipt của mình; không public, không client sửa trạng thái xử lý |
| `reports/{uid}/submissions/{requestId}/evidence/{imageId}` | Đề xuất minh chứng nhỏ riêng tư ở R7; không URL public |

Catalog Firestore chỉ để xác thực tham chiếu và lookup ngoài vùng khám phá, không là
nguồn danh sách quanh đây. Import từ OSM thật theo vùng hỗ trợ bằng local admin tool,
không service account trong app/repo. Rules nền tảng mới triển khai một phần theo
[trạng thái R0](REAL_DATA_R0_STATUS.md); catalog và adapter production chưa có.
POI chỉ mới thấy qua thử nghiệm mà chưa đăng ký: cho đọc, nhưng không giả lưu review
thành công; R1 phải giải quyết đăng ký catalog trước nghiệm thu tính năng ghi R4.

- Review identity là cặp `(placeKey, uid)` ở mọi route, key, cursor và kiểm tra trùng.
- Fields phục vụ query như `hasPhotos`, `isEdited`, `status`, timestamps cần validation
  tương ứng trong rules; userId/placeKey/createdAt bất biến khi sửa.
- Chốt bài mới public hay pending tại R0. Đề xuất public với nội dung owner hợp lệ;
  owner không được tự unhide bài bị khóa; không dựng quy trình admin UI ngoài phạm vi.
- Tránh tên/avatar snapshot tự khai trong review: resolve từ public profile hoặc rules
  đối chiếu hồ sơ hiện tại khi ghi; quy định rõ cập nhật tên ảnh cho bài cũ.
- Không cho client tự ghi điểm trung bình, histogram, số review hoặc quyền.

## 5. Các đợt thực hiện và tiêu chí nghiệm thu

### R0 — Chốt hợp đồng dữ liệu, môi trường và rules

Phụ thuộc: không. Hoàn thành trước mọi đợt ghi dữ liệu.

- Kiểm tra project thực tế đang Spark, Auth email/password và Cloudinary Free;
  giữ nguyên Firebase native config, không nhầm với Google Maps/Places key.
- Chốt vùng thử nghiệm, vùng phát hành ban đầu, dataset/ID và schema ở mục 4.
- Chốt giới hạn review/ảnh, trường profile hỗ trợ, trạng thái publication và quotas.
- Thêm cấu hình emulator, rules/index có version, error mapper và bootstrap môi trường.
- Viết rules tests cho guest/owner/user khác, field giả, target sai, nội dung hidden,
  cả get/list/query và create/update/delete. Test bằng emulator trước deploy.
- Đầu ra: schema/query matrix + các quyết định được ghi lại, bộ rules test chạy được;
  danh sách thao tác Console còn cần thực hiện được nêu rõ, không báo đã cấu hình nếu chưa có bằng chứng.

### R1 — Quán OSM thật, GPS và nền khám phá 5 km

Phụ thuộc: R0 cho catalog; thử nguồn có thể làm trước phần ghi Firestore.

- Tạo adapter POI/mapper/cache, xử lý node/way/relation, dữ liệu thiếu/trùng và ID hỏng.
- Thử Overpass có kiểm soát ở ít nhất ba vị trí; đối chiếu thủ công tên/tọa độ/quán quen.
  Ghi số POI, thời gian, dữ liệu thiếu; không coi ít kết quả là lỗi GPS nếu OSM thiếu quán.
- Chuẩn bị pipeline gói khu vực và local spatial query; cập nhật hợp đồng Home hiện
  `fetchPlaces()` không nhận tâm/limit để không tiếp tục ngầm tải danh sách toàn cục.
- Home/Map dùng chung vị trí, bán kính 5 km, chọn tâm thủ công và nút tìm khu vực.
- Đầu ra: di chuyển tâm đổi đúng quán; mọi marker thuộc vùng truy vấn theo quy tắc khoảng
  cách; hủy/response cũ không ghi đè; có cache, offline/stale/error/empty rõ ràng.
- Cổng nghiệm thu: nguồn đủ hữu ích tại vùng mục tiêu và có cách phân phối phù hợp ngân
  sách 0. Nếu không đạt, điều chỉnh vùng/phạm vi trước R2, không thay bằng quán giả.

### R2 — Home, Search/Filter, Category, Detail và chỉ đường

Phụ thuộc: R1.

- Thay DemoPlaceRepository bằng nguồn thật cho từng capability, giữ test overrides.
- Search tiếng Việt không dấu, taxonomy, scope AND filter, sort/cursor trên toàn tập
  phù hợp trong vùng đã chọn; không lọc một page rồi báo total toàn vùng.
- Bỏ nhãn xếp hạng tuần/gợi ý cá nhân khi không có nguồn. Filter/ranking theo điểm app
  chưa có chỉ mục tương ứng thì ghi chưa hỗ trợ, không rank từ vài card đã tải.
- Detail lookup theo ID phải hoạt động khi deep link/restart hoặc quán ngoài tâm hiện tại.
  Catalog/cache cũ hiển thị ngày nguồn và trạng thái unavailable khi không còn xác minh.
- Menu/giờ mở cửa/giá/ảnh thiếu có empty state. Không lấy ảnh quán gắn vào bài review mới.
- Chỉ đường mở ứng dụng ngoài; không tích hợp Google Routes API hoặc coi đây là tính quãng đường.
- Đầu ra: Home → Search/Category → Detail → Map/Back đúng quán, giữ context/scroll;
  ảnh lỗi, tên dài, không có địa chỉ và ID mất đều xử lý được.

### R3 — Auth, hồ sơ và Settings thật

Phụ thuộc: R0; có thể thực hiện sau R1 trước R2 nếu cần.

- Nghiệm thu register/login/logout/reset email, session sau restart bằng tài khoản thật.
- Tạo hồ sơ public idempotent, bao gồm tài khoản Auth cũ chưa có doc; xử lý Auth tạo xong
  nhưng ghi profile lỗi mà không tạo account lại. Email không nằm trong public doc.
- Chốt nguồn danh tính hiện hành và thứ tự đồng bộ Auth/Firestore; ghi lỗi từng bước,
  retry được khi lưu tên/avatar chỉ thành công một bên, không toast thành công toàn bộ.
- Hỗ trợ bio/khu vực bằng Firestore nếu giữ trên UI. Username độc nhất chỉ thêm khi có
  transaction/rules đặt chỗ; nếu chưa làm thì loại khỏi phạm vi field được sửa.
- Lưu light/dark/system qua restart bằng local preferences; không ghi setting theme vào
  public profile. Giữ reset password/logout hoạt động; nội dung support/privacy phải có nguồn thật.
- Đầu ra: hai tài khoản độc lập, không private state/draft còn lại sau logout/đổi user.

### R4 — Review, ảnh, All Reviews, My Reviews và Gallery

Phụ thuộc: R0 + R1/R2 (place identity/catalog) + R3 (identity).

- Implement toàn bộ capability của review adapter hiện tại: create/update/delete,
  exact media lookup, place preview/feed, user summary/page/change signal.
- Đổi ID create về UID trong scope quán; sửa public reviewer duplicate check đang chỉ
  dùng review.id. Gửi lại sau timeout không tạo bài thứ hai; không ghi đè bài cũ khi create.
- Bỏ seed ảnh quán trong form. Upload ảnh bytes trước khi ghi review; lưu secureUrl/publicId,
  giữ URL đã upload để retry, không bỏ qua ảnh mới như demo hiện tại.
- Cloudinary unsigned preset giới hạn kích thước/định dạng; chỉ dùng cho ảnh public.
  Không gọi đây là xác thực owner của ảnh hoặc chống lạm dụng hoàn chỉnh. Nếu cần ký/xóa,
  thực hiện qua công cụ tin cậy tại máy phát triển; không nhét API Secret vào Flutter.
- Lỗi upload/lưu riêng, form giữ draft, chặn submit trùng và session đổi giữa thao tác.
  Chỉ báo lưu xong khi server xác nhận; offline pending không coi là đã đăng.
- Thống kê dùng Firestore count/sum/average và các query count theo sao trên public scope,
  cache/invalidate sau mutation, không cần Cloud Functions và không suy histogram từ average.
  Kiểm chứng SDK/chi phí đọc ở R0/R4; không nhân nhiều aggregation cho mọi card mỗi build.
- Điểm card lấy từ nguồn tổng hợp đã kiểm chứng hoặc chưa hiển thị; ranking theo điểm
  toàn vùng chỉ bật khi có read model đầy đủ, được tạo từ dữ liệu thật bằng tool tin cậy.
- Gallery phân trang media có nguồn review, áp dụng status trước query/limit; không quét
  toàn bộ review chỉ để lấy ảnh. My Reviews có filter/count/paging theo owner.
- Đầu ra: A tạo/sửa/xóa, B đọc được nội dung public nhưng không sửa được; restart và
  thiết bị thứ hai thấy dữ liệu; summary khớp bài public, retry không nhân bản bài/ảnh.

### R5 — Favorites và Muốn ghé

Phụ thuộc: R0 + R2 + R3.

- Hai adapter Firestore riêng; cải thiện state loading/error của stream, lỗi ghi có
  phản hồi và rollback đúng thao tác, không hoàn tác response tài khoản cũ lên user mới.
- Tải quán theo IDs/catalog theo lô có giới hạn, không lọc từ danh sách Home 5 km.
  Giữ quán ở xa trong danh sách đã lưu, có not-found/stale riêng từng item.
- Query/paging theo tài khoản và semantics tìm/sort rõ; nếu chỉ tìm trên số item đã tải
  phải ghi rõ hoặc đổi contract, không giả tìm hết bộ sưu tập.
- Đầu ra: lưu/bỏ ở mọi màn đồng bộ, hai tập độc lập, giữ sau restart và đổi thiết bị.

### R6 — Collections, Editor và hồ sơ công khai

Phụ thuộc: R3 + R4 + R5.

- Lưu create idempotent/update/delete collections theo owner, tối đa 50 quán; chốt
  inline membership để không cần Functions dọn subcollection. Metadata count/cover có
  nguồn membership, không cộng từ Favorites/Muốn ghé.
- Bộ chọn quán tái sử dụng Search vùng hiện tại; quán cũ ngoài vùng vẫn resolve theo ID.
- Public profile query public reviews bằng collection group + index/status/owner trước
  sort/count/limit; không email, private draft/report/favorites hoặc tên demo.
- Stats/featured có quy tắc cụ thể, null khi chưa có; tên/avatar đọc từ public profile.
- Đầu ra: B không đọc/sửa collection của A; guest xem profile public; cùng một tác giả
  có bài ở nhiều quán không bị deduplicate sai khi reviewId đều là UID.

### R7 — Report và minh chứng riêng tư không Functions

Phụ thuộc: R0 + R2 + R3 + R4 + R6.

- Thay submit demo bằng direct Firestore write được rules kiểm soát; target phải tồn
  tại trong catalog/review/public profile. Reporter UID/path, reason, field whitelist,
  timestamp/status ban đầu và retry/requestId được kiểm tra; client không tự xử lý report.
- Chốt giới hạn gửi theo tài khoản/ngày bằng counter và transaction/rules kiểm chứng;
  giới hạn phía UI không thay thế rules. Không tuyên bố chống spam mạnh như backend tin cậy.
- Không upload minh chứng lên Cloudinary public. Phương án thử cho ngân sách 0:
  nén ảnh nhỏ, mỗi ảnh là Firestore Bytes doc riêng có quyền private (đề xuất tối đa
  2 ảnh × 150 KiB), lưu báo cáo + evidence nguyên tử và tắt indexing trường bytes.
  Phải đo quota/storage, giới hạn kích thước trong rules và kiểm tra tính khả thi trước áp dụng;
  không giữ giả định cũ 3 ảnh × 5 MB. Đây là phương án đánh đổi cho quy mô nhỏ, không kho media lớn.
- Nếu giải pháp evidence không đạt quyền riêng tư/quota, báo rõ blocker và đề xuất báo
  cáo text-only để người dùng quyết định giảm phạm vi; không tự coi upload evidence đã xong.
- Dùng Console/local tool với quyền tin cậy để kiểm tra receipt; không thêm admin UI,
  email/push hoặc tự động moderation. Xóa ảnh orphan/retention bằng quy trình thủ công rõ ràng.
- Đầu ra: receipt chỉ có sau persist, retry không trùng; B/guest không đọc minh chứng
  của A, client không sửa status; không URL public và không secret trong app.

### R8 — Loại demo khỏi runtime và nghiệm thu toàn app

Phụ thuộc: R1–R7 đạt các tiêu chí trong phạm vi đã chốt.

- Audit provider mặc định, hardcoded fixtures/ID/avatar/rating/giá/badge, demo assets và
  nút thành công giả. Fixtures chỉ ở test hoặc chế độ demo tường minh, không fallback khi API lỗi.
- Cập nhật docs/README: phần thực sự hoàn tất, vùng hỗ trợ, quota, cache/staleness và
  nội dung còn thiếu. Không đánh dấu luồng hoàn tất nếu chỉ widget test pass.
- Tối ưu theo số request/read/write/upload đo được: không request trong build,
  listener chỉ trên màn cần thiết, page giới hạn, cache có TTL, dispose/reset đúng.
- Chạy Flutter 3.47.5: format, analyze, toàn bộ tests, rules emulator, git diff --check.
- Nghiệm thu Android/iOS: GPS denied/off/manual center, mạng chậm/offline, API 429/504,
  Firestore permission/quota error, upload một phần, account switch và app restart.
- Kiểm tra light/dark, 320/390/428 px, text scale, ảnh lỗi, bàn phím và Back/deep link.
- Kịch bản cuối: tìm quán thật 5 km → Detail → login → review + ảnh → người khác xem
  → favorite/muốn ghé/collection → edit/delete → report private → restart/đổi tài khoản.
- Release chỉ dùng nguồn khám phá được phép cho mô hình phân phối đã chọn; public
  Overpass không là backend production ngầm. Không yêu cầu nâng gói khi quota không đủ.

## 6. Thứ tự giao việc và theo dõi

Thứ tự đề xuất: R0 → R1 → R2 → R3 → R4 → R5 → R6 → R7 → R8.
R5 có thể làm trước R4 sau khi R2/R3 xong để có mốc persistence nhỏ dễ nghiệm thu.
Không đổi toàn bộ provider trong một lượt; mỗi đợt có diff/test/bằng chứng native riêng.
Branch tính năng dùng `feat/`, rules repo tiếp tục áp dụng; không tự commit/push/deploy.

Mỗi đợt ghi: chưa làm / đang làm / chờ cấu hình hoặc quyết định / đã kiểm thử / luồng
hoàn tất; kèm file thay đổi, test, screenshot/log an toàn, quota đo và giới hạn còn lại.
Không đặt thời hạn cố định trước khi R0/R1 xác nhận nguồn POI và dữ liệu môi trường.

## 7. Các quyết định phải giải quyết trước phần phụ thuộc

| Quyết định | Mặc định đề xuất | Chốt ở |
| --- | --- | --- |
| Vùng dữ liệu phát hành | Khu vực thực tế người dùng muốn kiểm thử, chưa tự chọn thành phố | R0/R1 |
| Nguồn production ngân sách 0 | Gói OSM khu vực + query local, Overpass chỉ thử nghiệm | R1 |
| Profile identity/publication | Hồ sơ public riêng, review hợp lệ public, status backend khóa | R0/R3 |
| Giới hạn review/ảnh | Có giới hạn rõ, nén trước upload; thống nhất form/domain/rules | R0/R4 |
| Rating sort toàn vùng | Chỉ bật khi có nguồn đủ và query đúng, không dùng loaded-page ranking | R2/R4 |
| Private evidence | Thử Bytes nhỏ trong Firestore; text-only cần quyết định giảm phạm vi nếu không đạt | R7 |
| Bảo trì media/report | Tool/Console chạy thủ công, không server trả phí hoặc admin UI | R4/R7 |

## 8. Nguồn đối chiếu

- [Firebase Spark và dịch vụ](https://firebase.google.com/pricing).
- [Firestore quota](https://firebase.google.com/docs/firestore/quotas).
- [Aggregation queries](https://firebase.google.com/docs/firestore/query-data/aggregation-queries).
- [Rules unit tests](https://firebase.google.com/docs/rules/unit-tests).
- [OpenFreeMap](https://openfreemap.org/).
- [Overpass public instance](https://dev.overpass-api.de/overpass-doc/en/preface/commons.html).
- [Giấy phép OSM](https://www.openstreetmap.org/copyright).
- [Cloudinary Free](https://cloudinary.com/pricing) và
  [upload](https://cloudinary.com/documentation/upload_images).

Gói/quota/chính sách phải đối chiếu lại lúc tích hợp; kế hoạch không chứng minh Console
đã đúng hoặc tài khoản đã có đủ quota. Tài liệu backend cũ được cập nhật theo từng đợt;
khi mâu thuẫn với hướng demo/seed cũ, dùng kế hoạch này cho lộ trình chuyển dữ liệu thật.
