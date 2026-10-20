# Food Review — Tính năng chính và hướng phát triển

Bản tổng hợp phạm vi sản phẩm, cập nhật 19/10/2026. Đây là nguồn duy nhất về danh sách
và mức ưu tiên tính năng; chi tiết màn hình ở [kế hoạch UI](UI_IMPLEMENTATION_PLAN.md),
luồng ở [routing](food_review_luong_hoat_dong_routing.md), dữ liệu/quyền ở
[backend](BACKEND_SETUP.md). Các mục dự kiến không phải tính năng đã triển khai.

## 1. Hiện trạng

- Đã có nền T01–T02: design system Inter/Material 3, light/dark/system, bốn tab giữ trạng thái,
  route và placeholder cho các màn dự kiến; khu vực admin từ chối truy cập mặc định.
- Demo có danh sách quán; Search tìm tên quán/món không dấu, query/filter/sort/phân trang và recent trong phiên; chi tiết,
  yêu thích đồng bộ trong RAM và loading/empty/error/retry/not-found.
- Firebase đã khởi tạo trên Android/iOS; T10 đã có adapter Auth email/password/session/logout,
  UI Login, T11 Register và T12 Forgot Password đã có, cùng guard/returnTo và reset favorites theo user. Chưa nghiệm thu tài khoản thật;
  Firestore vẫn chưa tích hợp. Xem [LOGIN_AUTH_UI.md](LOGIN_AUTH_UI.md).
- T08 Map đã có truy vấn vùng/marker/card quán demo, lọc, GPS foreground theo yêu cầu và mở chỉ đường ngoài; xem [MAP_UI.md](MAP_UI.md). Chưa nghiệm thu GPS/chỉ đường trên thiết bị thực và nền OSM đang bị lỗi DNS trong môi trường kiểm tra.
- T07 Category đã có banner, món con, tìm kiếm/lọc/sort, query scope và phân trang;
  giữ trạng thái qua Detail/Back và đổi tab. Dùng dữ liệu demo hiện có, chưa tích hợp backend;
  xem [CATEGORY_UI.md](CATEGORY_UI.md).
- T09a All Reviews đã có summary, histogram, lọc/sort, cursor paging, chia sẻ và CTA
  theo quán; dùng bốn review demo, chưa tích hợp backend/Auth hay màn viết/gallery/profile/report.
  Xem [ALL_REVIEWS_UI.md](ALL_REVIEWS_UI.md).
- T09b Gallery đã có lọc/lưới, viewer swipe/zoom, exact review media, index/Back và
  chia sẻ; dùng ảnh demo, upload/lưu ảnh chưa tích hợp. Xem [GALLERY_UI.md](GALLERY_UI.md).
  T10 Login/Auth, T11 Register, T12 Forgot Password, T13 Write Review, T14 Edit/Delete Review, T15 Favorites, T16 Want to Visit và T17 My Profile đã triển khai UI/adapter; task tiếp theo là T18 Edit Profile.
- T03 Home, T04 Chi tiết quán, T05–T06 Search/Filter, T15 Favorites, T16 Want to Visit và T17 My Profile đã triển khai UI/demo (xem HOME_UI.md, RESTAURANT_DETAIL_UI.md, SEARCH_UI.md, FAVORITES_UI.md, WANT_TO_VISIT_UI.md, MY_PROFILE_UI.md); backend và các luồng phụ thuộc chưa hoàn tất. Hai danh sách địa điểm, profile fields và lựa chọn theme chưa lưu qua restart;
  tọa độ/ảnh demo không phải dữ liệu quán đã xác minh. Web chưa có FirebaseOptions.

## 2. Tính năng chính — MVP

| Nhóm | Phạm vi cần hoàn thành | Task UI |
| --- | --- | --- |
| Tài khoản | Đăng ký email/mật khẩu, đăng nhập/đăng xuất, giữ phiên, quên mật khẩu; tạo hồ sơ lần đầu; validation và lỗi rõ ràng | T10–T12 |
| Khám phá | Home, tìm tên có chuẩn hóa tiếng Việt không dấu, lọc danh mục; sắp xếp theo điểm/số review; dữ liệu thật và phân trang | T03, T05–T07 |
| Chi tiết quán | Ảnh/thư viện toàn màn hình, tên, địa chỉ, danh mục, mô tả, điểm/số review, danh sách review; ID sai có trạng thái riêng | T04, T09a–T09b |
| Review | Một review/người/quán; 1–5 sao, nội dung và ảnh thư viện/camera; tạo/sửa/xóa bài của mình; upload/retry/chống gửi trùng; aggregate do backend tính | T13–T14 |
| Yêu thích | Lưu/bỏ theo tài khoản, đồng bộ Home/chi tiết/tab Yêu thích, đọc lại sau restart, lỗi ghi có hoàn tác | T15 |
| Bản đồ và vị trí | OSM/marker mở chi tiết, GPS foreground theo yêu cầu, khoảng cách gần đúng, mở ứng dụng ngoài để chỉ đường; từ chối GPS vẫn dùng được | T08, T04 |
| Hồ sơ và cài đặt | Xem/sửa tên/avatar, email riêng tư, review của tôi, đăng xuất; chọn light/dark/system, ghi rõ khả năng lưu lựa chọn | T17–T20 |

Khách được đọc nội dung công khai. Thao tác cá nhân cần đăng nhập, giữ đích quay lại hợp lệ;
không tự gửi review/report sau đăng nhập. Giới hạn nội dung/số ảnh/dung lượng phải chốt
trước T13 và thống nhất UI/backend; nhiều ảnh và xem ảnh lớn đã thuộc MVP.

## 3. Mở rộng đã có kế hoạch UI — sau luồng cốt lõi

Các mục này thuộc kế hoạch hiện tại nhưng chưa triển khai, không mặc nhiên nằm trong MVP.

| Tính năng | Phạm vi | Task |
| --- | --- | --- |
| Muốn ghé thăm | Danh sách theo tài khoản, độc lập với yêu thích | T16 |
| Bộ sưu tập | Tạo/sửa tên, mô tả và danh sách quán; mặc định riêng tư, kiểm tra owner | T21–T22 |
| Thông báo trong app | Inbox, đã đọc/chưa đọc, mở đúng nội dung; backend tạo thông báo; push là hạng mục riêng | T23 |
| Hồ sơ người đánh giá | Tên/avatar, review và thống kê công khai có nguồn; không lộ email | T24 |
| Báo cáo và quản trị | Báo cáo quán/review/user có lý do, minh chứng tùy chọn; admin lọc/xem/xử lý/ẩn nội dung, lưu lịch sử; không xóa vĩnh viễn mặc định | T25–T27 |

Tìm kiếm nâng cao ở T06 chỉ bật tiêu chí đã có dữ liệu. Layout editor bộ sưu tập và admin
còn thiếu thiết kế riêng; có route/placeholder không có nghĩa đã có chức năng.

## 4. Ý tưởng có thể phát triển thêm

Đây là backlog đề xuất, chưa cam kết triển khai. Chọn theo giá trị sử dụng, dữ liệu,
độ phức tạp, chi phí và khả năng vận hành/kiểm duyệt.

| Ưu tiên | Nhóm ý tưởng | Phụ thuộc chính |
| --- | --- | --- |
| P1 — Khám phá và review | Lọc giá, điểm tối thiểu, ẩm thực/món ăn, tiện ích, giờ mở cửa, khu vực/bán kính/vùng bản đồ; tìm toàn văn, gom marker; điểm nhiều tiêu chí/phân bố sao; đánh dấu hữu ích; lịch sử đã xem có xóa/tắt | Dữ liệu có nguồn, query/index hoặc dịch vụ tìm kiếm/địa lý; công thức điểm và chống vote lặp |
| P1 — Ảnh và chia sẻ | Nén/thumbnail/cache ảnh, dọn ảnh mồ côi, kiểm duyệt ảnh; chia sẻ quán/bộ sưu tập/review bằng link có web dự phòng | Backend quản lý media, deep link, quyền riêng tư khi chia sẻ |
| P2 — Cá nhân hóa và cộng đồng | Gợi ý theo sở thích bằng quy tắc trước ML; theo dõi người viết/feed, bình luận/phản hồi, huy hiệu/thống kê đóng góp, danh sách chủ đề có bình chọn | Dữ liệu tương tác, hồ sơ công khai, chống spam và kiểm duyệt |
| P3 — Kế hoạch đi ăn | Ghi chú/nhãn riêng, ngày dự kiến, nhắc hẹn tự nguyện; nhóm bạn chia sẻ và bình chọn quán; giờ mở cửa theo ngày/ngày nghỉ, đề xuất sửa thông tin | Phân quyền thành viên, lịch/thông báo và nguồn giờ mở cửa tin cậy |
| P4 — Tin cậy và tài khoản | Xác minh email, Google/Apple login, xóa tài khoản/dữ liệu; xác minh chủ quán, phát hiện spam, kiểm duyệt tự động hỗ trợ, khiếu nại quyết định, chặn/bỏ chặn user | Backend xác minh quyền, xử lý dữ liệu/ảnh, quy trình hỗ trợ và kiểm duyệt |
| P5 — Kinh doanh | Cổng chủ quán, quản lý chi nhánh/phản hồi review/thống kê; đặt bàn; ưu đãi/voucher; quảng bá có nhãn tài trợ; đặt món/giao hàng/thanh toán/hoàn tiền | Đối tác, ngân sách, vận hành và chính sách riêng; ngoài MVP |
| Xuyên suốt | Cache/offline tốt hơn, tối ưu hiệu năng, đa ngôn ngữ Việt/Anh, push có tùy chọn tắt, analytics tối thiểu và App Check | Đo nhu cầu/chi phí, quyền riêng tư và dịch vụ phù hợp |

Không đưa chat trực tiếp hay chương trình khách hàng thân thiết vào MVP. Lịch sử xử lý
báo cáo đã thuộc T27; mở rộng P4 bổ sung chống spam/khiếu nại, không lặp chức năng này.

## 5. Lộ trình và tiêu chí hoàn thành

1. Giữ nền T01–T02; dựng khám phá/chi tiết/map/review đọc T03–T09 theo Stitch.
2. Nối Auth và dữ liệu thật; hoàn thiện tạo/sửa/xóa review, ảnh, yêu thích và hồ sơ.
3. Nghiệm thu MVP; sau đó làm muốn ghé, collections, inbox, hồ sơ công khai, report/admin.
4. Rà tích hợp T28–T29 theo phạm vi phát hành; chọn ý tưởng P1–P5 khi có nhu cầu/nguồn lực.

Backend làm cùng từng feature, không đợi T28 mới tích hợp. Mốc 4–5 tuần cũ chỉ là ước lượng
MVP hẹp, không phải cam kết cho toàn bộ T01–T29 và backlog mở rộng.

Điều kiện nghiệm thu mỗi phạm vi phát hành:

- Dữ liệu đọc lại sau restart; không lộ dữ liệu tài khoản A khi logout/login B;
  favorite, muốn ghé và collection độc lập; chỉ điều hướng sau khi lưu thành công.
- Backend/rules bảo vệ owner/admin, validate field; aggregate đáng tin cậy;
  test emulator guest/owner/user khác/admin trước deploy; seed quán bằng công cụ admin.
- Loading/empty/error/retry, mạng yếu, upload lỗi một phần, draft, double submit,
  ID sai/nội dung bị ẩn và quyền GPS đều có cách xử lý; không dùng thành công giả.
- UI kiểm tra light/dark, 320/390/428px, chữ lớn, bàn phím, semantic label và ảnh lỗi.
- Format/analyze/test CI, kiểm thử Auth → quán → review → yêu thích, thiết bị Android/iOS;
  ghi lỗi release an toàn, môi trường dev/prod tách biệt, không có secret trong client/Git.
- Release có icon/splash/version, privacy policy, cấu hình ký riêng và metadata;
  README/ảnh/video demo ghi rõ dữ liệu mẫu, tích hợp thiếu và bằng chứng kiểm thử.

Trạng thái theo bằng chứng: **chưa làm → đang làm → UI đã duyệt → chờ tích hợp → luồng hoàn tất**.
Trước mỗi ý tưởng mới, ghi ngắn vấn đề/người dùng, luồng, dữ liệu/API/quyền, dịch vụ/chi phí,
ưu tiên và tiêu chí nghiệm thu; không tự thêm nghiệp vụ chỉ vì thiết kế có nút.
