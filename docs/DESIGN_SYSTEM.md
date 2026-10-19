# Shared Flutter design system

Nguồn: [Vietnamese Food Review App trên Stitch](https://stitch.withgoogle.com/projects/17045709860825880180), đọc qua Stitch MCP ngày 18/10/2026.

- **00 - Global Design System** là design-system asset `assets/8f45df058264439b96fa58219b76fbd0` (version 2), không phải screen HTML.
- **01 - UI Kit** là screen `53a46cee31ef40fb91a52aa0b6dda3fd`; triển khai dựa trên HTML của cả 10 nhóm thành phần.
- Light giữ màu thương hiệu theo style guidelines: forest `#2F6B4F`, canvas linen `#F8F6F0`, orange `#F28C45`, rating gold `#F5B942`. Các mã Material tự sinh trong HTML có khác biệt (ví dụ primary `#125238`); core chọn palette thương hiệu trong Global Design System làm quy chuẩn. Màu accent dùng cho container; màu chữ accent dùng sắc đậm để dễ đọc.
- Stitch chỉ cung cấp theme light. Dark là bản bổ sung theo cùng thương hiệu, có các cặp màu foreground/background riêng.

## Cách dùng

```dart
import 'package:food_review/shared/design_system/design_system.dart';

AppButton(
  label: 'Lưu địa điểm',
  icon: Icons.bookmark_border,
  isLoading: saving,
  onPressed: save,
);

AppTextField(
  label: 'Mật khẩu',
  isPassword: true,
  validator: validatePassword,
);

AppToast.show(context, 'Đã lưu quán', type: AppFeedbackType.success);
```

Các component chỉ nhận dữ liệu và callback; không phụ thuộc route, repository hay model của feature. Feature adapter (ví dụ `PlaceCard`) chịu trách nhiệm nối dữ liệu, điều hướng và Riverpod.

## Tokens và theme

- `core/theme/app_tokens.dart`: spacing 4/8/12/16/24/32, lề 20, gutter 12; góc input/button 12, card 16, sheet 24; semantic success/warning/rating qua `ThemeExtension`.
- `core/theme/app_theme.dart`: `AppTheme.light`, `AppTheme.dark`, cùng cấu hình Material cho app bar, button, field, card, chip, bottom navigation, snackbar, dialog, sheet, progress.
- Inter variable TTF được bundle offline, hỗ trợ tiếng Việt. Giấy phép SIL OFL nằm trong `assets/fonts/OFL.txt`. Font từ google/fonts, không tải font lúc runtime.
- Kiểu chữ: headline 24/32, 20/28, 18/26; title 16/22; body 16/24 và 14/20; label 13/18, 12/16, caption 11/14. Giữ text scaling của hệ điều hành.
- Dùng `context.colors`, `context.textStyles`, `context.semanticColors`; không hardcode màu nền/chữ trong feature.
- `semanticColors.onImage` là chữ sáng trên ảnh có scrim tối, khai báo cả light/dark và hỗ trợ copyWith/lerp; dùng cho banner Category.
- `themeModeProvider`: mặc định `ThemeMode.system`, có thể đổi light/dark ngay trên toàn ứng dụng bằng `ref.read(themeModeProvider.notifier).setMode(...)`. Lựa chọn hiện lưu trong phiên ứng dụng, chưa lưu xuống thiết bị.

## Thành phần theo UI Kit

| Nhóm Stitch | API dùng chung |
| --- | --- |
| 01 Buttons | `AppButton`: primary, secondary, outline, text, destructive; loading/disabled; `AppIconButton` có tooltip |
| 02 Form fields | `AppTextField`: label/helper/error, Form validator, password toggle, verified, keyboard/autofill; `AppSearchField`: clear, filter callback và badge filterCount |
| 03 Restaurant cards | `AppRestaurantCard`: ảnh 16:9 hoặc compact 88px, title/category/rating/price/distance/address/badge/open state/favorite |
| 04 Ratings | `AppRating`, `AppRatingInput`, `AppRatingSummary` |
| 05 Review card | `AppReviewCard`: reviewer, verified/rank, rating, text, dish tags, gallery, helpful, replies, more/profile callbacks |
| 06 Chips | `AppChip`, `AppBadge` với neutral/primary/accent/success/warning/error |
| 07 User & headings | `AppAvatar`: 28/40/56px, initials/image/online; `AppSectionHeader`: title/subtitle/action và bố cục thích ứng chữ lớn |
| 08 Feedback | `AppToast`, `AppEmptyState`, `AppErrorState`, `AppSkeleton`, `AppRestaurantSkeleton` |
| 09 Overlays | `showAppConfirmation` trả bool, `showAppBottomSheet<T>` hỗ trợ safe area/keyboard/scroll; `RangeSlider` theo theme |
| 10 Navigation | `AppBottomNavigation` nhận destinations và callback; catalog minh hoạ 4 tab theo Stitch |

Tiện ích bổ sung:

- `AppImage`: ảnh mạng hoặc assets với placeholder/fallback theo theme khi không có ảnh, đang tải hoặc lỗi.
- `AppErrorMessage.from`: chuyển lỗi ứng dụng sang nội dung cho người dùng; exception ngoài `AppException` dùng fallback, không hiện chi tiết SDK. `AppException.message` phải là nội dung an toàn để hiển thị, được tạo tại repository boundary.
- `AppFormatters.price`, `priceRange`, `distance`: định dạng VN; giá trong card dùng tabular figures.
- `AppMessage` giữ tương thích các màn hình cũ và chuyển sang empty/error component mới.

AppRating có `showValue: false` để dùng dải sao trong summary/review mà không lặp điểm.
AppReviewCard ẩn helpful/replies khi chưa có callback, tránh hiển thị thao tác không khả dụng.

## Tích hợp và xem thử

`MaterialApp.router` đã dùng light/dark/system. Màn hình khám phá dùng search/chip/card/skeleton mới; màn chi tiết T04 dùng ảnh/menu/review preview và thanh giá/chỉ đường (xem [RESTAURANT_DETAIL_UI.md](RESTAURANT_DETAIL_UI.md)); các màn tải dữ liệu dùng error mapper và retry chung. Tab hồ sơ có chọn giao diện và nút **Xem UI Kit** (`/design-system`). Catalog bao gồm toàn bộ 10 nhóm để phát triển tính năng tiếp theo.

App shell có 4 tab theo T02; Bản đồ T08 dùng marker giá và card quán với theme light/dark, Trang chủ theo Stitch T03; xem [MAP_UI.md](MAP_UI.md) và [HOME_UI.md](HOME_UI.md) cho bằng chứng và các tích hợp còn thiếu. Component điều hướng hỗ trợ danh sách tùy ý; catalog minh hoạ 4 tab theo thiết kế. Các card không tự tạo dữ liệu giá, khoảng cách hoặc ảnh nếu repository chưa cung cấp.

Skeleton tôn trọng giảm chuyển động và TickerMode. Password toggle, rating, icon buttons có nhãn trợ năng; form error/toast hỗ trợ thông báo trạng thái. Nút có vùng chạm tối thiểu 48px, icon button 44px; bố cục tránh khoá chiều cao để hỗ trợ chữ lớn.

Search/Filter T05–T06 tái sử dụng field/chip/section/card/overlay và thanh CTA theo Stitch; xem [SEARCH_UI.md](SEARCH_UI.md).
Category T07 dùng `AppRestaurantCard.insetImage`: ảnh có padding 12/góc 8, card góc 12,
title/tag, rating, giá và địa chỉ xuống dòng theo độ rộng; variant cũ giữ nguyên.
Search và Category chia sẻ `PlaceSearchResults` với SliverList lazy, skeleton/empty/error/retry/paging;
`SearchActiveFilters.defaultSort` cho phép Category mặc định đánh giá cao. Xem [CATEGORY_UI.md](CATEGORY_UI.md).

## Kiểm tra

```sh
flutter analyze
flutter test
```

Bộ test kiểm tra loading/disabled chống submit, clear và đổi search controller, password/validation, rating, dialog cancel/confirm, đổi theme qua route, toàn bộ catalog ở 320px với text scale 1.6 ở cả light/dark, và các luồng domain/search/detail/favorite/retry sẵn có.
