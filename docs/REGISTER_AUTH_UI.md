# T11 — Register/Auth

Ngày triển khai: 19/10/2026. Branch: `feat/register-auth`, từ T10 Login/Auth.

Đã đọc màn **14 - Register** bằng Stitch MCP từ [Food Review](https://stitch.withgoogle.com/projects/17045709860825880180), screen ID `1bc1d0042a40439b82bbf713483971dc`.

Màn Flutter giữ bố cục dọc của thiết kế: logo Food Review, badge “Ẩm Thực Việt”, tiêu đề tạo tài khoản, mô tả, bốn trường tên/email/mật khẩu/xác nhận, đồng ý điều khoản, CTA đăng ký và liên kết quay về đăng nhập. Prototype QA accordion và dữ liệu giả trong HTML không được đưa vào ứng dụng.

Form dùng SafeArea, scroll, giới hạn rộng 440px, hỗ trợ 320/390/428px, chữ lớn, dark mode, bàn phím, autofill và hiện/ẩn mật khẩu. Tên được trim, email được trim trước request, password giữ nguyên; controller được dispose khi rời màn.

`FirebaseAuthRepository.signUp` gọi `createUserWithEmailAndPassword`, sau đó cập nhật `displayName` trên Firebase Auth. Nếu tạo account thành công nhưng cập nhật tên thất bại, app báo tài khoản đã tạo để người dùng đăng nhập và không đăng ký lặp. Lỗi email đã dùng, password yếu, email sai và mạng được map sang thông báo tiếng Việt an toàn.

Đăng ký thành công tự tạo session Auth và quay về `returnTo` hợp lệ; không tự thực hiện lại favorite/review. Back/cancel không submit. Nếu Firebase chưa khởi tạo, repository báo dịch vụ chưa sẵn sàng, không tạo tài khoản giả. Firestore profile document chưa tích hợp; `displayName` hiện được lưu trong Firebase Auth và việc đồng bộ `users/{uid}` sẽ thuộc phần backend tiếp theo.

Các file chính:

- `lib/features/auth/presentation/register_screen.dart`: UI, validation, lifecycle và điều hướng.
- `lib/features/auth/presentation/auth_providers.dart`: controller đăng ký qua repository.
- `lib/features/auth/domain/auth_validation.dart`: validation tên/email/password/xác nhận/điều khoản.
- `lib/features/auth/data/firebase_auth_repository.dart`: adapter Firebase Auth và map lỗi.
- `lib/core/router/app_router.dart`: route `/register`, giữ returnTo/action.
- `test/register_screen_test.dart`, `test/auth_repository_test.dart`: kiểm tra responsive, validation, retry, context và SDK mapping.

Giới hạn còn lại: chưa kiểm thử bằng tài khoản thật vì chưa có tài khoản thử nghiệm và chưa xác nhận Email/Password đã bật trong Firebase Console; chưa có Firestore profile repository. T12 — Forgot Password sẽ nối `sendPasswordResetEmail` vào contract Auth.

Ảnh đối chiếu: [light](screenshots/register-light.png), [dark](screenshots/register-dark.png). Tái tạo bằng `flutter test test/register_screen_test.dart --dart-define=REGISTER_CAPTURE=true`.
