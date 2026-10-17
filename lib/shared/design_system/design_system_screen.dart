import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_mode_provider.dart';
import 'design_system.dart';

/// Living component catalog, accessible from profile and /design-system.
class DesignSystemScreen extends ConsumerStatefulWidget {
  const DesignSystemScreen({super.key});
  @override
  ConsumerState<DesignSystemScreen> createState() => _DesignSystemScreenState();
}

class _DesignSystemScreenState extends ConsumerState<DesignSystemScreen> {
  int _rating = 4;
  bool _favorite = false, _chip = true, _helpful = false;
  RangeValues _range = const RangeValues(30, 120);
  @override
  Widget build(BuildContext context) {
    void toast(String text) =>
        AppToast.show(context, text, type: AppFeedbackType.success);
    Widget section(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: title),
        const SizedBox(height: 12),
        ...children.expand((w) => [w, const SizedBox(height: 12)]),
        const SizedBox(height: 12),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Food Review — UI Kit')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            Text(
              'Warm Culinary Minimal',
              style: context.textStyles.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '00 — Global Design System · 01 — UI Kit',
              style: context.textStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ThemeMode>(
              isExpanded: true,
              initialValue: ref.watch(themeModeProvider),
              decoration: const InputDecoration(labelText: 'Giao diện'),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Theo hệ thống'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Sáng')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setMode(mode);
                }
              },
            ),
            const SizedBox(height: 24),
            section('Màu sắc & kiểu chữ', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in {
                    'Primary': context.colors.primary,
                    'Accent': AppColors.orange,
                    'Rating': context.semanticColors.rating,
                    'Error': context.colors.error,
                    'Success': context.semanticColors.success,
                  }.entries)
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: entry.value,
                            borderRadius: AppRadii.inputBorder,
                          ),
                        ),
                        Text(entry.key, style: context.textStyles.labelSmall),
                      ],
                    ),
                ],
              ),
              Text(
                'Khám phá ẩm thực Việt',
                style: context.textStyles.headlineLarge,
              ),
              Text(
                'Quán ngon quanh bạn',
                style: context.textStyles.headlineMedium,
              ),
              Text(
                'Phở tái lăn, bánh cuốn, cà phê trứng — Ẩm thực Việt đầy hương vị.',
                style: context.textStyles.bodyMedium,
              ),
            ]),
            section('01 · Nút bấm', [
              for (final variant in AppButtonVariant.values)
                AppButton(
                  label: variant.name,
                  variant: variant,
                  expanded: true,
                  icon: Icons.restaurant_menu,
                  onPressed: () => toast('Đã chọn ${variant.name}'),
                ),
              const AppButton(
                label: 'Đang xử lý',
                onPressed: null,
                isLoading: true,
              ),
              const AppButton(label: 'Chưa khả dụng', onPressed: null),
              Wrap(
                spacing: 8,
                children: [
                  AppIconButton(
                    icon: Icons.bookmark_border,
                    tooltip: 'Lưu địa điểm',
                    onPressed: () => toast('Đã lưu địa điểm'),
                  ),
                  AppIconButton(
                    icon: Icons.share_outlined,
                    tooltip: 'Chia sẻ',
                    onPressed: () => toast('Đã chọn chia sẻ'),
                  ),
                ],
              ),
            ]),
            section('02 · Ô nhập liệu', [
              const AppSearchField(),
              const AppTextField(
                label: 'Email',
                hintText: 'ban@example.com',
                isVerified: true,
                keyboardType: TextInputType.emailAddress,
              ),
              const AppTextField(label: 'Mật khẩu', isPassword: true),
              const AppTextField(
                label: 'Số điện thoại',
                errorText: 'Số điện thoại không hợp lệ. Vui lòng nhập lại (10 chữ số).',
              ),
            ]),
            section('03 · Thẻ nhà hàng', [
              AppRestaurantCard(
                name: 'Phở Bò Gia Truyền Bát Đàn',
                category: 'Món Việt • Phở truyền thống',
                rating: 4.8,
                reviewCount: 328,
                priceLabel: '55.000đ - 85.000đ',
                distanceLabel: '1.2 km',
                address: 'Hoàn Kiếm',
                badge: 'Nổi tiếng',
                isOpen: true,
                isFavorite: _favorite,
                onFavorite: () => setState(() => _favorite = !_favorite),
              ),
              const AppRestaurantCard(
                name: 'Bánh Mì Phố Cổ Hà Nội',
                category: 'Ăn vặt & Bánh mì kẹp',
                compact: true,
                rating: 4.6,
                reviewCount: 194,
                priceLabel: '25.000đ - 45.000đ',
              ),
            ]),
            section('04 · Đánh giá & sao', [
              const AppRatingSummary(value: 4.8, count: 524),
              AppRatingInput(
                value: _rating,
                onChanged: (v) => setState(() => _rating = v),
              ),
            ]),
            section('05 · Thẻ đánh giá', [
              AppReviewCard(
                reviewerName: 'Trần Nhật Nam',
                timeLabel: '2 ngày trước',
                content: 'Nước dùng phở ngọt thanh chuẩn vị Bắc, thịt bò mềm và thơm nức mùi gừng hành.',
                rating: 5,
                verified: true,
                reviewerBadge: 'Thực thần cấp 4',
                dishes: const ['Phở tái lăn', 'Quẩy giòn'],
                helpfulCount: _helpful ? 25 : 24,
                isHelpful: _helpful,
                onHelpful: () => setState(() => _helpful = !_helpful),
              ),
            ]),
            section('06 · Chips & bộ lọc', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppChip(
                    label: 'Phở & Bún',
                    selected: _chip,
                    onSelected: (v) => setState(() => _chip = v),
                  ),
                  AppChip(
                    label: 'Gần tôi nhất',
                    icon: Icons.near_me,
                    selected: !_chip,
                    showCheckmark: true,
                    onSelected: (v) => setState(() => _chip = !v),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tone in AppBadgeTone.values)
                    AppBadge(label: tone.name, tone: tone),
                ],
              ),
            ]),
            section('07 · Người dùng & tiêu đề', [
              const Wrap(
                spacing: 24,
                children: [
                  AppAvatar(
                    name: 'Hoàng Linh',
                    size: AppAvatarSize.large,
                    isOnline: true,
                  ),
                  AppAvatar(name: 'Minh Anh', isOnline: true),
                  AppAvatar(
                    name: 'Quốc Thái',
                    size: AppAvatarSize.small,
                    isOnline: true,
                  ),
                ],
              ),
              AppSectionHeader(
                title: 'Quán nổi bật hôm nay',
                subtitle: 'Được tuyển chọn kỹ lưỡng',
                onAction: () => toast('Xem tất cả'),
              ),
            ]),
            section('08 · Trạng thái phản hồi', [
              AppButton(
                label: 'Thông báo thành công',
                onPressed: () =>
                    toast('Đã lưu vào danh sách Yêu thích thành công!'),
              ),
              AppButton(
                label: 'Thông báo lỗi',
                variant: AppButtonVariant.outline,
                onPressed: () => AppToast.show(
                  context,
                  'Không thể tải dữ liệu',
                  type: AppFeedbackType.error,
                ),
              ),
              AppEmptyState(
                title: 'Chưa có quán yêu thích',
                message: 'Lưu những quán ngon bạn muốn thử.',
                actionLabel: 'Khám phá ngay',
                onAction: () => toast('Khám phá ngay'),
              ),
              const AppRestaurantSkeleton(),
              AppErrorState(onRetry: () => toast('Đang thử lại')),
            ]),
            section('09 · Dialog & Bottom sheet', [
              AppButton(
                label: 'Xem hộp thoại xác nhận',
                variant: AppButtonVariant.outline,
                onPressed: () async {
                  final confirmed = await showAppConfirmation(
                    context,
                    title: 'Xoá khỏi danh sách yêu thích?',
                    message: 'Bạn có chắc muốn bỏ lưu địa điểm đã chọn?',
                    confirmLabel: 'Xoá bỏ',
                    destructive: true,
                  );
                  if (confirmed && context.mounted) toast('Đã bỏ lưu địa điểm');
                },
              ),
              AppButton(
                label: 'Xem bộ lọc',
                onPressed: () => showAppBottomSheet<void>(
                  context,
                  title: 'Bộ lọc tìm kiếm',
                  builder: (sheetContext) => StatefulBuilder(
                    builder: (context, update) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Khoảng giá: ${_range.start.round()}.000đ - ${_range.end.round()}.000đ',
                        ),
                        RangeSlider(
                          values: _range,
                          min: 0,
                          max: 300,
                          divisions: 30,
                          labels: RangeLabels(
                            '${_range.start.round()}.000đ',
                            '${_range.end.round()}.000đ',
                          ),
                          onChanged: (v) => update(() => _range = v),
                        ),
                        AppButton(
                          label: 'Áp dụng',
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
            section('10 · Thanh điều hướng', [
              AppBottomNavigation(
                selectedIndex: 0,
                onSelected: (_) {},
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home),
                    label: 'Trang chủ',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.map_outlined),
                    label: 'Bản đồ',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.favorite_border),
                    label: 'Yêu thích',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'Cá nhân',
                  ),
                ],
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
