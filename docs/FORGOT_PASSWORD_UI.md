# T12 — Forgot Password

Màn `/forgot-password` được đối chiếu với Stitch screen **15 - Forgot Password** (`f9d97df3f6384637adad3124a6038d80`) trong project `17045709860825880180`.

## Phạm vi đã triển khai

- Header có nút quay lại, tiêu đề và avatar; nội dung nằm trong `SafeArea`, cuộn được và giới hạn chiều rộng 440dp.
- Brand Food Review, minh họa email/khóa, tiêu đề, mô tả, ô email, CTA gửi hướng dẫn và ghi chú bảo mật bám theo bố cục Stitch.
- Trạng thái thành công hiển thị thông báo chung để không tiết lộ email có tồn tại hay không; có thể gửi lại hoặc quay về Login.
- Link Login giữ `returnTo` và `action` hợp lệ để không làm mất ngữ cảnh auth gate.
- Hỗ trợ light/dark theme, màn hình 320–428dp và text scale lớn.

## Luồng dữ liệu

`ForgotPasswordScreen` gọi `ForgotPasswordController` qua Riverpod, controller gọi `AuthRepository.resetPassword`. Firebase adapter dùng `sendPasswordResetEmail`; lỗi `user-not-found` được coi là thành công để tránh account enumeration. Khi Firebase chưa khởi tạo, adapter unavailable trả lỗi thân thiện.

Email reset thật còn phụ thuộc Email/Password provider, authorized domains và email template trong Firebase Console. Không có dữ liệu mẫu trong màn này; email người dùng là dữ liệu nhập trực tiếp.

## File chính

- `lib/features/auth/presentation/forgot_password_screen.dart`: UI, validation, trạng thái gửi và điều hướng.
- `lib/features/auth/presentation/auth_providers.dart`: controller Riverpod.
- `lib/features/auth/domain/auth_repository.dart`: contract `resetPassword`.
- `lib/features/auth/data/firebase_auth_repository.dart`: Firebase adapter và mapping lỗi.
- `lib/features/auth/presentation/login_widgets.dart`: brand và minh họa dùng chung.
- `lib/core/router/app_router.dart`: route `/forgot-password`.

Ảnh render kiểm tra nằm tại `docs/screenshots/forgot-light.png` và `docs/screenshots/forgot-dark.png`. Kiểm tra bằng:

```sh
flutter test test/forgot_password_screen_test.dart --dart-define=FORGOT_CAPTURE=true
```
