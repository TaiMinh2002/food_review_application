# T01–T02 — Nền thiết kế, dữ liệu và điều hướng

Ngày đối chiếu: 18/10/2026. Branch: `feat/design-routing`.
Phạm vi: hoàn thiện nền T01–T02; **chưa triển khai Home T03**, Auth T10 hoặc các feature mới.

## Nguồn thiết kế

Project [Vietnamese Food Review App](https://stitch.withgoogle.com/projects/17045709860825880180) đã được kiểm tra lại bằng Stitch MCP.
Mapping 23 screen có nhãn trong mục 7 của [kế hoạch](UI_IMPLEMENTATION_PLAN.md) vẫn khớp metadata.
Global Design System là asset `assets/8f45df058264439b96fa58219b76fbd0`, không phải screen HTML.
Không dùng các instance ẩn hoặc tên “Generating…” làm nguồn triển khai.

Giữ palette thương hiệu và component API trong [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md):
forest `#2F6B4F`, linen `#F8F6F0`, orange `#F28C45`, gold `#F5B942`, font Inter.
CSS màu Material sinh riêng ở từng screen không tự động thay đổi theme toàn ứng dụng.
Mỗi task UI sau này phải đọc lại ảnh/HTML screen tương ứng; danh mục hiện tại không thay thế việc review thiết kế.

## Inventory màn – route – dữ liệu

Screen ID đầy đủ nằm ở mục 7 của kế hoạch. Nhãn Stitch dưới đây chỉ là tên tham chiếu; route và ID mới là định danh.

| Stitch / màn | Canonical route | Dữ liệu cần | Trạng thái sau T02 |
| --- | --- | --- | --- |
| 02 Home | `/home` | Quán, danh mục, section gợi ý, vị trí tham chiếu | Dùng nguyên `PlacesScreen` cũ; chờ T03 |
| 03 Restaurant Detail | `/restaurants/:restaurantId` | Place theo ID | Màn demo hiện có; chờ nâng UI T04 |
| 04 Search & Filter | `/search` | Query, filter, sort, quán | Placeholder T05 |
| 16 Filter & Sort | `/search/filters` | Filter nháp/đã áp dụng | Placeholder T06 |
| 17 Category Results | `/categories/:categoryId` | Category ID, quán | Placeholder T07 |
| 08 Map | `/map` | Toạ độ, vị trí/quyền GPS, quán | Tab placeholder T08 |
| 05 All Reviews | `/restaurants/:restaurantId/reviews` | Review list + summary đúng quán | Placeholder T09a |
| 07 Restaurant Gallery | `/restaurants/:restaurantId/gallery` | Ảnh, query `index` | Placeholder T09b |
| 13 Login | `/login` | Auth state, email/password, `returnTo` | Màn thông báo cũ; chờ T10 |
| 14 Register | `/register` | Auth + tạo profile | T11 đã có UI/adapter Auth; Firestore profile còn chờ |
| 15 Forgot Password | `/forgot-password` | Email + reset service | T12 đã có UI/adapter; email thật còn chờ Firebase Console |
| 06 Write Review | `/restaurants/:restaurantId/reviews/create` | Quán, session, draft, upload | Placeholder T13 |
| Form edit dùng lại 06 | `/reviews/:reviewId/edit` | Review, owner, định danh quán | Placeholder T14 |
| 09 Favorites | `/favorites` | Place IDs đã lưu + quán | Màn demo RAM hiện có; chờ T15 |
| 10 Want to Visit | `/want-to-visit` | Tập saved riêng theo user | Placeholder T16 |
| 11 My Profile | `/profile` | Session, profile, thống kê | Màn khởi đầu cũ; chờ T17 |
| 12 Edit Profile | `/profile/edit` | Profile, avatar upload | Placeholder T18 |
| 18 My Reviews | `/my-reviews` | Review theo user | T14/T19 đã có UI/demo, filter và phân trang; xem MY_REVIEWS_UI.md |
| 19 Settings | `/settings` | Theme/account preferences | Placeholder T20 |
| 22 Collections | `/collections` | Collections theo owner | Placeholder T21 |
| Editor chưa có screen riêng | `/collections/create`, `/collections/:collectionId/edit` | Tên, membership, owner | Placeholder T22 |
| 20 Notifications | `/notifications` | Inbox, read state, target | Placeholder T23 |
| 21 Public Reviewer Profile | `/users/:userId` | Public profile và review | Placeholder T24 |
| 23 Report Content | `/reports/create` | Target type/ID, reason, ảnh | Placeholder T25 |
| Admin chưa có screen riêng | `/admin/reports` | Report list, role backend | Từ chối truy cập, chờ T26 |
| Admin detail chưa có screen riêng | `/admin/reports/:reportId` | Report, role, audit | Từ chối truy cập, chờ T27 |
| 01 UI Kit | `/design-system` | Các component dùng chung | Catalog hiện có |

Không có feature mới được nối backend trong đợt này. Placeholder không đọc/ghi dữ liệu cá nhân và không giả lập gửi form thành công.

## Phân loại dữ liệu và fixtures

| Trường / nội dung | Hiện tại | Cách xử lý ở task UI tiếp theo |
| --- | --- | --- |
| ID, tên, địa chỉ, category, mô tả, lat/lng | Demo trong repository, không phải địa điểm xác minh | Giữ nhãn demo; thay implementation khi có nguồn thật |
| Ảnh | Default chưa có; fixture tùy chọn lấy URL tham chiếu từ HTML Home Stitch | Ảnh minh họa, không chứng minh đúng địa điểm; URL có thể hết hạn; dùng fallback |
| `averageRating`, `reviewCount` | Model có, demo hiện là 0 | Không hiển thị review giả hay tự suy ra phân bố sao |
| Giá, giờ mở cửa, tiện ích | Chưa có field/nguồn | Chờ contract/schema; không bịa số liệu trong widget |
| Badge Michelin/verified, xếp hạng tuần | Chưa có nguồn xác minh/aggregate | Chưa hỗ trợ; cần dữ liệu trước khi hiện như thông tin thật |
| Khoảng cách, thời gian đi bộ | Có toạ độ demo, chưa có vị trí tham chiếu/quãng đường | Không hardcode khoảng cách hoặc suy ra thời gian di chuyển |
| Danh tính, notification, public stats | Chưa có repository thật | Không dùng số liệu Stitch làm dữ liệu tài khoản thật |
| Favorite | RAM dùng chung trong phiên demo | Chưa có auth gate; chuyển sang async theo user ở T15 |
| Want-to-visit / collection | Chưa có repo | Tách dữ liệu riêng; không tự nhập favorite sang list khác |

`DemoPlaceRepository(data: ...)` nhận dữ liệu tùy chọn và snapshot bất biến. Default vẫn là danh sách cũ để không thay Home trước T03.

```dart
placeRepositoryProvider.overrideWithValue(
  DemoPlaceRepository(data: DemoPlaceFixtures.withImages),
);
```

`DemoPlaceFixtures` cung cấp `withImages`, `withoutImages`, `brokenImages`, `empty`.
Trường hợp ID không tồn tại dùng `getPlace('missing')`. Loading/error/retry được kiểm tra bằng repository override có Future chờ/lỗi trong tests, không thêm độ trễ hoặc lỗi ngẫu nhiên vào demo mặc định.

## Quyết định CTA và thiết kế thiếu

- Search, filter, category, “Xem tất cả”: đích đã đăng ký; nội dung/hành vi thực hiện T03/T05–T07. Chưa coi query trên URL là bộ lọc đã được áp dụng.
- Viết review từ Home: phải chọn quán trước, rồi đi qua Auth ở T10/T13. Chưa mở form hoặc tự đăng bài trong T02.
- Avatar/thông báo/map/favorite: dùng route đã định danh; quyền và dữ liệu thật thuộc task feature tương ứng.
- “Xem thực đơn”, huy hiệu foodie, helpful, follow, bình luận, đặt bàn: ngoài luồng đã chốt; chưa thêm chức năng hoặc xác nhận thành công giả. Khi dựng UI phải ẩn/giải thích rõ hoặc bổ sung đặc tả trước.
- Collection Editor, admin list/detail chưa có screen riêng có nhãn; cần layout trước khi duyệt UI. Guest variants và form sửa review cần đối chiếu riêng.
- Quyền riêng tư collection, một review/người/quán, giới hạn ảnh, quy tắc tiếp tục save sau login, role/admin transitions vẫn là đề xuất trong kế hoạch; chốt trước task nghiệp vụ liên quan.

## Hợp đồng điều hướng T02

- `AppRoute` trong `lib/core/router/app_route.dart` là danh mục path/name/title/task. Dùng `location(parameters: ..., query: ...)` để encode ID thay vì nối chuỗi từ input.
- 4 branch dùng indexed stack: Trang chủ, Bản đồ, Yêu thích, Cá nhân. Đổi tab giữ state; chọn lại tab hiện tại trở về route gốc branch, không chủ động xóa query/filter cục bộ.
- Detail và các màn chức năng khác nằm trên root navigator; dùng `push` khi mở từ một màn để Back về đúng nguồn. Không hiện bottom bar trên detail/root overlays.
- Back trên app bar hoặc hệ thống: pop khi có trang trước; direct link root không có history thì về `/home`. Home có thể thoát ứng dụng theo hành vi hệ thống.
- URL cũ `/places`, `/places/:placeId`, `/sign-in` redirect sang `/home`, `/restaurants/:restaurantId`, `/login`; giữ query. `/` vào Home. URL không tồn tại có màn lỗi và nút Back/Home.
- `restaurantId` trên URL truyền vào repository dưới tên `placeId`; không đổi tên cả feature/domain.
- `/login?returnTo=...` giữ đích đã biết trong app và ngữ cảnh qua query; đích ngoài app, auth loop, admin, path bất thường hoặc không tồn tại bị loại. Đây là chuẩn bị cho T10, chưa có tự đăng nhập/tiếp tục hành động.
- Admin luôn hiển thị từ chối khi chưa xác minh quyền; chưa có cờ client tự cấp quyền và chưa gọi API admin. T26 phải bổ sung enforcement backend.
- Public/guest policy và auth guards toàn feature vẫn chờ T10. Favorites demo tiếp tục hoạt động như cũ, không được coi là lưu theo tài khoản.

## Kiểm chứng

Test router bao gồm 4 tab giữ query, redirect URL cũ giữ query, return-to hợp lệ/không hợp lệ, detail mở từ Favorites quay lại đúng tab, Back trực tiếp/system, toàn bộ route placeholder và admin bị từ chối.
Các test hiện có về favorite, tìm kiếm, lỗi/retry và theme tiếp tục được chạy.
Fixtures được kiểm tra qua repository, không cần mạng. Ảnh mẫu không được xác nhận là luôn tải được.

Không đánh dấu T03 hoặc các màn placeholder là hoàn tất UI. Screenshot shell dùng để kiểm tra nhãn/thứ tự/thích ứng navigation; chưa có ảnh Home mới để so với thiết kế.

Kết quả kiểm tra đợt này: format/analyze đạt, toàn bộ 23 test đạt; có kiểm tra loading Future chờ. Đối chiếu đủ 26 route của đặc tả với `AppRoute`.
Ảnh render shell light 390px và Map placeholder dark 320px/text scale 1.6 đã được xem trực tiếp, không có overflow.
Preview được tạo bằng Flutter widget renderer, chưa thay thế chạy app native hoặc kiểm tra GPS/backend.
