# R3 — Auth, Hồ sơ công khai và Cài đặt thật

Cập nhật 23/10/2026. Triển khai trên nhánh `feat/settings`, rebase từ `origin/dev` sau khi merge Restaurant Detail UI.

## Đã nối và chuẩn hóa

1. **Lưu Cài đặt Theme qua khởi động lại (Local Preferences Persistence)**:
   - Thêm package `shared_preferences: ^2.5.6` vào dependencies.
   - Xây dựng `ThemeRepository` (`SharedPreferencesThemeRepository` và `InMemoryThemeRepository` fallback).
   - Tích hợp `themeModeProvider` trong `lib/core/theme/theme_mode_provider.dart`:
     - Tự động nạp giá trị theme đã lưu (`light` / `dark` / `system`) khi khởi động app.
     - Cập nhật UI tức thời và ghi xuống `SharedPreferences` ở background.
     - Mặc định fallback `InMemoryThemeRepository` khi chưa có instance preferences (giúp toàn bộ 399 widget tests hiện có chạy deterministic mà không cần sửa code test cũ).
   - Khởi tạo và truyền `sharedPreferencesProvider` tại `lib/main.dart`.

2. **Đồng bộ Hồ sơ công khai Firestore (`users/{uid}`)**:
   - `FirebaseProfileRepository` (`lib/features/profile/data/firebase_profile_repository.dart`):
     - Cập nhật danh tính Auth (`user.updateProfile`) kèm đồng bộ thông tin công khai (`displayName`, `photoUrl`, `updatedAt`) lên Firestore collection `users/{uid}` bằng `SetOptions(merge: true)`.
     - Thứ tự đồng bộ an toàn: Nếu Auth thành công nhưng Firestore gặp sự cố, báo lỗi rõ ràng "chưa đồng bộ được hồ sơ công khai" thay vì giả định thành công hoàn toàn.
     - Hỗ trợ hook `onSyncProfile` phục vụ kiểm thử đơn vị độc lập.
   - `FirebaseAuthRepository` (`lib/features/auth/data/firebase_auth_repository.dart`):
     - Khi `signUp` thành công, tự động khởi tạo document hồ sơ `users/{uid}` ban đầu một cách idempotent.
     - Không lưu email hay role vào document công khai.

3. **Cách ly Phiên và Đăng xuất (Session Boundary)**:
   - Đăng xuất yêu cầu xác nhận `showAppConfirmation`, xóa toàn bộ form nháp và private route stack.
   - `favoriteRepositoryProvider` và `favoriteIdsProvider` phản ứng tự động theo `authSessionProvider`: khi user đăng xuất, danh sách favorite trong RAM được xóa sạch tức thì.

## Kiểm chứng và Test

- Bộ test mới: `test/settings_theme_persistence_test.dart` (7 tests pass):
  - Unit test `SharedPreferencesThemeRepository`: đọc `light`/`dark`, fallback `system` khi giá trị không hợp lệ, ghi giá trị vào preferences.
  - Test persistence: đổi theme từ dark sang light, simulate restart với `ProviderScope` mới đọc từ cùng preferences.
  - Test đồng bộ hồ sơ: `FirebaseProfileRepository` gọi sync, kiểm tra xử lý lỗi an toàn; `FirebaseAuthRepository.signUp` tạo user và doc khởi tạo.
- Bộ test hiện có:
  - `test/settings_screen_test.dart`: 14 tests pass.
  - `test/auth_repository_test.dart`: 5 tests pass.
  - `test/edit_profile_test.dart`: 10 tests pass.
  - `test/register_screen_test.dart`: 9 tests pass.
  - `test/login_screen_test.dart`: 9 tests pass.
