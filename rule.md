# Quy tắc phát triển Food Review

File này là quy ước bắt buộc cho contributor và coding agent trong các task tiếp theo. Đọc cùng `AGENTS.md` trước khi sửa repository. Yêu cầu trực tiếp của người dùng trong task được ưu tiên; nếu thay đổi quy ước lâu dài, cập nhật tài liệu để các lượt sau áp dụng nhất quán.

## 1. Phạm vi và cách bắt đầu task

- Đọc yêu cầu, kiểm tra branch, `git status` và code liên quan trước khi sửa. Giữ nguyên các thay đổi có sẵn ngoài phạm vi; không reset, clean hoặc ghi đè công việc khác.
- Đọc `docs/ARCHITECTURE.md`, `docs/DESIGN_SYSTEM.md` và task tương ứng trong `docs/UI_IMPLEMENTATION_PLAN.md` khi làm tính năng/UI.
- Xác định phần được làm, phụ thuộc, tiêu chí hoàn thành và phần chưa triển khai. Không tự làm task kế tiếp khi người dùng đã giới hạn phạm vi.
- Kiểm tra code hiện có trước khi tạo abstraction, widget, repository hoặc dependency mới.

## 2. Đặt tên và quản lý branch

Branch phải thể hiện **loại công việc và mục đích phát triển**, không đặt theo tên công cụ hoặc người thực hiện.

| Loại thay đổi | Tiền tố | Ví dụ |
| --- | --- | --- |
| Tính năng/UI mới | `feat/` | `feat/t03-home-ui` |
| Sửa lỗi | `fix/` | `fix/restaurant-detail-back-navigation` |
| Cải tổ code giữ nguyên hành vi | `refactor/` | `refactor/shared-review-form` |
| Tài liệu | `docs/` | `docs/contributor-rules` |
| Test | `test/` | `test/auth-return-to` |
| Công cụ, cấu hình, bảo trì | `chore/` | `chore/flutter-ci` |
| Bản sửa khẩn cấp cho release | `hotfix/` | `hotfix/login-session-expiry` |

- Dùng chữ thường, tiếng Anh và dấu gạch ngang; có thể thêm task ID. Ví dụ T01–T02: `feat/t01-t02-design-routing`.
- Không dùng `codex/`, `agent/`, `ai/` hoặc tên người làm làm tiền tố mặc định. Với repository này, feature dùng `feat/`.
- Kiểm tra nhánh đích và thay đổi chưa commit trước khi tạo/chuyển branch; dùng base người dùng yêu cầu hoặc base phát triển đã xác định của repository. Không tự reset/rebase để ép đúng base.
- Không tạo branch mới cho từng file hoặc task con khi chúng thuộc cùng phạm vi đã thống nhất. Branch hiện tại đúng phạm vi thì tiếp tục dùng.
- Commit có nội dung rõ như `feat: add four-tab navigation`. Không tự merge, force-push hoặc xóa branch ngoài yêu cầu.

## 3. Kiến trúc và trách nhiệm từng tầng

```text
Screen / Widget → Riverpod Provider / Controller → Repository contract
                                                      ↑
                                      Data implementation → SDK / HTTP
```

- Giữ cấu trúc feature-first: `features/<feature>/{domain,data,presentation}`. Không đổi cấu trúc toàn dự án chỉ để giống một ví dụ tài liệu.
- `domain/`: model và contract Dart thuần; không import Flutter, Firebase hoặc HTTP SDK.
- `data/`: repository implementation, DTO/mapper, tích hợp dịch vụ và chuyển lỗi SDK thành lỗi ứng dụng.
- `presentation/`: UI và state của feature. Widget không gọi trực tiếp Firestore/Auth/HTTP, không chứa quy tắc nghiệp vụ lớn.
- Dùng Riverpod để cấp dependency và quản lý trạng thái; repository có thể override trong test. Không tạo singleton/service toàn cục mới để né dependency injection.
- Router chỉ định nghĩa route, tham số, redirect và guard; không tải nghiệp vụ hoặc xử lý upload trong router.
- Dùng `core/` cho hạ tầng toàn app; `shared/` cho thành phần thực sự tái sử dụng. Không đưa logic riêng của một feature vào đây.

## 4. Tái sử dụng và chia file hợp lý

- Ưu tiên widget, formatter, validator, error mapper và theme token đã có. Không copy cùng một card/form/dialog qua nhiều màn.
- Phần dùng ở nhiều feature đưa vào shared với API dữ liệu/callback rõ; không phụ thuộc route, repository hoặc state của một feature.
- Phần chỉ dùng nội bộ feature đặt cùng feature. Có thể gom các widget/hàm nhỏ liên quan trong một file; không tạo một file cho mỗi đoạn vài dòng.
- Mỗi file có một trách nhiệm chính. Tách theo section UI, controller, model hoặc data adapter khi chúng có trách nhiệm riêng và giúp đọc/test dễ hơn.
- **File code viết tay tối đa 700 dòng**, tính cả comment và dòng trống. Khi gần 500–600 dòng, đánh giá để tách trước khi chạm giới hạn. Không nén code hoặc bỏ format để lách số dòng.
- Không chia vụn file chỉ để giảm số dòng; không tạo tầng trung gian chỉ chuyển tiếp lời gọi mà không có giá trị. File sinh tự động/vendor không thuộc giới hạn và không sửa tay.
- Khi sửa file viết tay đã vượt 700 dòng, tách phần thuộc phạm vi task hợp lý; không mở rộng thành refactor toàn dự án.

## 5. Theme: bắt buộc hỗ trợ light và dark

- Mọi UI mới/sửa phải hoạt động với `ThemeMode.light`, `dark`, `system`, kể cả dialog, sheet, toast, skeleton và trạng thái disabled/error.
- **Không hardcode màu trong feature hoặc shared widget** bằng `Color(0x...)`, `Colors.white`, `Colors.black`, v.v. Không lấy trực tiếp palette `AppColors` để bỏ qua theme.
- Dùng `context.colors` cho vai trò Material, `context.semanticColors` cho màu ngữ nghĩa và `context.textStyles` cho typography.
- Khi thiếu màu: thêm vai trò có tên theo mục đích vào `core/theme/`, khai báo cho cả light/dark, rồi sử dụng qua theme. Với `ThemeExtension`, bổ sung cả `copyWith` và `lerp`. Hai mode có thể dùng cùng mã nếu phù hợp, nhưng vẫn phải khai báo tập trung.
- Không rải `brightness == Brightness.dark ? ... : ...` trong từng màn. Không đổi theme toàn app để chữa riêng một component.
- Dùng token spacing/radius/font hiện có; giá trị riêng chỉ dành cho hình học đặc thù có lý do. Hình ảnh và logo giữ màu gốc khi cần; màu nền/chữ/icon xung quanh vẫn qua theme.

```dart
final colors = context.colors;
Text(
  'Quán ăn gần bạn',
  style: context.textStyles.titleMedium?.copyWith(color: colors.onSurface),
);
```

## 6. UI, Stitch và khả năng sử dụng

- Dùng đúng project/screen ID; đọc ảnh và HTML trước khi dựng màn. Áp dụng Flutter widget và design system hiện tại; không nhúng HTML để thay UI native.
- Không tự sửa hoặc tạo lại màn Stitch khi nhiệm vụ chỉ là code theo thiết kế.
- Kiểm tra loading, empty, error/retry, ảnh lỗi, dữ liệu không tồn tại và guest/thiếu quyền khi có liên quan.
- Tôn trọng SafeArea, keyboard inset, scroll và text scaling; kiểm tra bề rộng 320/390/428px theo màn. Không khóa chiều cao khiến tiếng Việt hoặc chữ lớn bị cắt.
- Nút/icon có vùng chạm phù hợp, tooltip/semantic label khi cần; nội dung và lỗi dễ hiểu, không hiển thị exception SDK.
- CTA phải có hành vi rõ; feature chưa hỗ trợ cần trạng thái rõ ràng, không để nút giả hoạt động hoặc toast thành công giả.

## 7. State, dữ liệu và bất đồng bộ

- Dữ liệu qua repository; fixtures/demo tách khỏi widget và ghi rõ là minh họa. Không lấy số liệu trên Stitch làm dữ liệu thực của ứng dụng.
- Không tự bịa giá, badge, khoảng cách, xếp hạng, quyền hoặc thông tin người dùng khi chưa có nguồn dữ liệu.
- State phụ thuộc tài khoản phải reset khi logout/đổi tài khoản. Favorite, muốn ghé thăm và collection là các dữ liệu độc lập.
- Chống submit trùng và response tìm kiếm cũ ghi đè response mới. Sau `await`, kiểm tra lifecycle trước khi dùng context/cập nhật UI.
- Dispose controller, subscription, timer và HTTP client theo lifecycle. Không tạo request lặp trong `build`.
- Form lỗi phải giữ dữ liệu; chỉ điều hướng sau khi lưu thành công. Upload ảnh và ghi dữ liệu xử lý lỗi riêng; retry tránh tạo bản ghi/ảnh trùng.
- Danh sách lớn dùng query/phân trang theo contract, không tải toàn bộ backend chỉ để lọc trong widget.

## 8. Điều hướng, xác thực và bảo mật

- Dùng `AppRoute`, route name và helper encode tham số; ưu tiên ID thay vì truyền object bắt buộc qua bộ nhớ.
- Dùng `push` cho luồng cần Back về nguồn; chuyển tab qua shell. Không dùng `go('/home')` thay mọi hành vi Back.
- Giữ return-to nội bộ hợp lệ khi yêu cầu đăng nhập; không tự submit form/thực hiện hành động nhạy cảm chỉ vì login thành công.
- Guard phía client hỗ trợ trải nghiệm; backend/rules phải kiểm tra owner/admin. Không tin role hoặc user ID do form/client tự cung cấp.
- Không commit secret, service account, signing key hoặc local config. Không log token, mật khẩu hoặc dữ liệu cá nhân. `dart-define` không giấu được server secret.
- Không thêm package khi Flutter hoặc dependency hiện có đáp ứng hợp lý. Package mới cần lý do, tương thích nền tảng và cập nhật `pubspec.lock`.

## 9. Kiểm tra và bàn giao

- Chạy format/analyze và tests phù hợp cho thay đổi code; trước khi bàn giao code chạy bộ kiểm tra CI dưới đây. Thay đổi chỉ tài liệu kiểm tra nội dung/link/diff, không cần chạy lại Flutter tests vô cớ.
- Test hành vi có ý nghĩa: route/Back, state, validation, lỗi và quyền. Dùng repository override để test ổn định; không phụ thuộc mạng thật hoặc viết test chỉ lặp lại implementation.
- Với thay đổi UI, kiểm tra light/dark, màn nhỏ/chữ lớn và ảnh render. Với GPS/upload/native, kiểm tra trên nền tảng hỗ trợ và ghi rõ phần chưa chạy được.

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
git diff --check
```

- Tự rà diff: đúng phạm vi, không trùng component, không vượt 700 dòng, không màu cố định ngoài theme, không file tạm/debug/secret.
- Báo rõ branch, thay đổi chính, kết quả kiểm tra, demo/backend còn thiếu và trạng thái commit/push. Không báo pass nếu chưa chạy.
- Cập nhật tài liệu/trạng thái task theo bằng chứng. Phân biệt “UI đã duyệt” với “luồng hoàn tất”; placeholder không phải feature hoàn chỉnh.
