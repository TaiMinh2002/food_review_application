# T10 — Login/Auth

Ngày triển khai: 19/10/2026. Branch: `feat/login-auth`, từ `dev` đã merge T09b.
Trạng thái: UI và adapter Firebase Auth đã triển khai, chờ duyệt UI và nghiệm thu
Email/Password bằng tài khoản thật. Task UI tiếp theo: **T11 — Register**, rồi T12.

## Thiết kế và UI

Đã đọc ảnh/HTML bằng Stitch MCP từ
[project Food Review](https://stitch.withgoogle.com/projects/17045709860825880180),
màn **13 - Login**, ID `31ae3b9abb2b4e2d81bbefdf14ba05e6`.
Giữ logo 56px, huy hiệu ẩm thực, lời chào, thẻ ảnh phở, email/password,
quên mật khẩu, CTA và liên kết đăng ký; dùng Inter, màu ngữ nghĩa light/dark,
lề 20, khoảng cách 6/8/12/16/20/24 và góc bo hiện có. Form rộng tối đa 440px.
Không có thanh bốn tab trên Login theo thiết kế.

Back đặt cạnh header để hủy luồng, không đẩy toàn bộ logo xuống một hàng riêng.
SafeArea và trang cuộn hỗ trợ keyboard/chữ lớn/màn nhỏ; trường có autofill,
email keyboard, Next/Done, hiện/ẩn mật khẩu và thông báo lỗi trợ năng.
Mật khẩu không trim, không log và chỉ nằm trong controller của form; dispose khi rời màn.
Email được trim trước request. Validation đăng nhập kiểm tra email và mật khẩu không rỗng,
không áp quy tắc tạo mật khẩu mới lên tài khoản đang có.

Không sao chép email/mật khẩu có sẵn, số “12.000 địa điểm xác thực”, panel Prototype QA
hoặc thành công giả từ HTML. Ảnh phở dùng asset mẫu hiện có và ghi rõ minh họa;
nội dung quán vẫn là demo, **đăng nhập sử dụng Firebase Auth thật khi Firebase đã khởi tạo**.

## Auth và state

`FirebaseAuthRepository` thực thi signInWithEmailAndPassword/signOut,
chuyển SDK User thành UserProfile (không đọc Firestore/role hoặc gán quyền admin).
`authSessionProvider` theo dõi authStateChanges, có trạng thái loading/error/guest/user.
Nếu Firebase chưa khởi tạo, nguồn unavailable chỉ báo lỗi khi đăng nhập, không tạo
tài khoản demo hay coi người dùng đã đăng nhập. Auth state lỗi không được hiểu là guest
hoặc tiếp tục hiển thị nội dung riêng từ snapshot cũ.

Controller sign-in theo route, chặn request trùng và bỏ kết quả khi đã dispose.
Lỗi mạng, quá nhiều lần thử, provider chưa bật và credential lỗi được map sang tiếng Việt;
user-not-found/wrong-password/invalid-credential dùng cùng thông báo. Lỗi giữ nguyên input
để sửa/retry. Chỉ điều hướng khi session stream xác nhận user, không dựa vào toast hay
timeout giả. Logout có loading/error/retry; profile hiển thị tên/avatar từ Auth.

Phiên trên Android/iOS do Firebase SDK duy trì qua restart; app không lưu password/token
riêng và không thêm checkbox remember-me giả. Xem
[Firebase session persistence](https://firebase.google.com/docs/auth/flutter/start#persisting_authentication_state).
Hồ sơ public/edit, tài khoản bị vô hiệu hóa từ Console và refresh/reload quyền cần
nghiệm thu ở các luồng backend tương ứng; client guard không thay thế backend rules.

## Điều hướng và hành động cần tài khoản

- Router giữ nguyên instance/indexed stacks, dùng auth listener để refresh redirect.
  Trang riêng loading/error có AuthGate trước nội dung, không nháy placeholder riêng.
- Khách vẫn đọc Home/Search/Map/Category/Detail/All Reviews/Gallery/Public profile.
  Profile và Favorites hiện lời mời đăng nhập; chọn theme trong Profile vẫn dùng được.
- Viết/sửa review, muốn ghé, sửa hồ sơ, my reviews, thông báo, collections/tạo/sửa
  collection và báo cáo yêu cầu tài khoản. Các màn chưa làm vẫn là placeholder sau guard.
  Admin vẫn từ chối mặc định, không coi mọi user đăng nhập là admin.
- Guard lưu toàn bộ URL/quán/review/query vào `returnTo`. safeReturnTo chỉ nhận route
  nội bộ đã biết, chặn URL ngoài, admin, auth loop, fragment và đường dẫn bất thường.
- Login thành công pop về nguồn rồi mở target nếu khác nguồn; không dựng lại router
  hay luôn đẩy về Home. Direct link không có nguồn thì mở target/Home an toàn.
- Cancel/Back không submit hay thực hiện lại hành động. Request SDK đang chạy không
  hủy được ở client; nếu xác thực hoàn tất sau Back, phiên có thể đổi nhưng app không
  tự mở lại target hoặc toggle favorite.
- Favorite cần đăng nhập. Login giữ đúng quán và nhắc người dùng chạm lại tim để xác nhận;
  **không tự toggle sau login**. Repository RAM reset khi account thay đổi/logout,
  không nhập favorites guest vào tài khoản. Chưa lưu Firestore/qua restart (T15).
- Liên kết đăng ký/quên mật khẩu giữ returnTo/action; Back giữ draft Login.
  T11/T12 vẫn là placeholder. signUp hiện báo chưa tích hợp; reset password sẽ nối ở T12.

## File và trách nhiệm

| File | Nhiệm vụ |
| --- | --- |
| `lib/features/auth/data/firebase_auth_repository.dart` | Adapter SDK, map user/lỗi, sign-in/out và nguồn unavailable |
| `lib/features/auth/domain/auth_validation.dart` | Validation đăng nhập thuần Dart |
| `lib/features/auth/presentation/auth_providers.dart` | DI, session stream, controller sign-in/logout |
| `lib/features/auth/presentation/sign_in_screen.dart` | Form/draft/lifecycle, UI trạng thái, returnTo và links |
| `lib/features/auth/presentation/login_widgets.dart` | Header, thẻ ẩm thực mẫu, thông báo lỗi |
| `lib/features/auth/presentation/auth_gate.dart` | Loading/error/guest, chặn private content trước session |
| `lib/core/router/app_route.dart`, `app_router.dart` | Danh sách route riêng, redirect/refresh và query Login |
| `lib/features/favorites/presentation/favorite_providers.dart` | Auth gate thao tác và reset RAM theo user |
| `lib/features/profile/presentation/profile_screen.dart` | Phiên thật, đăng nhập/logout và theme hiện có |
| `lib/shared/widgets/app_button.dart` | iconAlignment tùy chọn; Login đặt mũi tên sau chữ, mặc định cũ giữ nguyên |

## Cấu hình và nghiệm thu còn lại

1. Kiểm tra native google-services.json/GoogleService-Info.plist trỏ đúng Firebase project.
2. Bật Email/Password trong Authentication → Sign-in method của Firebase Console theo
   [hướng dẫn Firebase](https://firebase.google.com/docs/auth/flutter/password-auth).
3. Dùng tài khoản thử nghiệm đã có trong project để kiểm tra đúng/sai credential,
   mạng lỗi, restart khôi phục phiên, signOut và đổi user trên Android/iOS.
4. Không commit password, token hoặc tài khoản thử nghiệm. T11 mới thêm tạo account/profile;
   T12 mới gửi reset email. Không yêu cầu người dùng đưa password vào chat/tài liệu.

Chưa có tài khoản thử nghiệm thật được cung cấp; chưa xác minh Console đã bật provider,
không báo đã nghiệm thu đăng nhập production. Web vẫn cần FirebaseOptions riêng.
Không thay native Firebase config, backend rules, map DNS hay thêm dependency trong T10.

## Kiểm chứng

- Unit tests cho adapter SDK → domain, trim email/giữ password, mapping lỗi, chống
  submit trùng/dispose và reset favorites khi logout/đổi user.
- Widget tests form light/dark ở 320/390/428px, scale 1/1.6, SafeArea và keyboard 300px;
  validation, show/hide, loading/failure/retry giữ input, link/cancel giữ draft.
- Routing tests guest/public/private/admin, session restore/loading/error/retry không
  lộ private content, returnTo/ID/Back, cancel khi request pending, favorite xác nhận lại,
  logout failure/success, unsafe target và router instance không thay khi session đổi.
- Các test tính năng cũ override phiên đăng nhập rõ ràng để tiếp tục kiểm tra luồng
  đã xác thực; guest/phiên lỗi được kiểm tra riêng. Không sửa thành công giả trong app.
- Build/run main thật trên iPhone 17 Pro simulator bằng Flutter 3.47.5; hot reload,
  ảnh runtime bằng Flutter inspector. Chưa nghiệm thu thao tác/tài khoản thật trên thiết bị.
- Kiểm tra cuối: format không thay đổi, `flutter analyze` không có lỗi,
  toàn bộ **193 tests pass**, `git diff --check` sạch. Các file mới đều dưới 700 dòng.

Ảnh: [light](screenshots/login-light.png), [dark](screenshots/login-dark.png),
[iOS light](screenshots/login-ios-light.png), [iOS dark](screenshots/login-ios-dark.png).
Tái tạo: `flutter test test/login_screen_test.dart --dart-define=LOGIN_CAPTURE=true`;
kết quả ở `build/login-screenshots/`. Kiểm tra CI: format, analyze, full tests và diff check.
