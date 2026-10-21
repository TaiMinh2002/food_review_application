import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/sign_out_action.dart';
import 'settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static String modeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Sáng',
    ThemeMode.dark => 'Tối',
    ThemeMode.system => 'Hệ thống',
  };

  Future<void> _chooseTheme(BuildContext context, WidgetRef ref) async {
    final selected = await showAppBottomSheet<ThemeMode>(
      context,
      title: 'Chế độ hiển thị',
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final mode = ref.watch(themeModeProvider);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Áp dụng cho toàn ứng dụng, chỉ lưu trong phiên hiện tại.',
                style: context.textStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final value in ThemeMode.values)
                ListTile(
                  title: Text(modeLabel(value)),
                  leading: Icon(switch (value) {
                    ThemeMode.system => Icons.brightness_auto_outlined,
                    ThemeMode.light => Icons.light_mode_outlined,
                    ThemeMode.dark => Icons.dark_mode_outlined,
                  }),
                  trailing: mode == value
                      ? Icon(Icons.check_circle, color: context.colors.primary)
                      : null,
                  selected: mode == value,
                  onTap: () => Navigator.pop(context, value),
                ),
            ],
          );
        },
      ),
    );
    if (!context.mounted || selected == null) return;
    ref.read(themeModeProvider.notifier).setMode(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final user = session.isLoading || session.hasError
        ? null
        : session.asData?.value;
    final mode = ref.watch(themeModeProvider);
    void login() => context.push(
      AppRoute.login.location(query: {'returnTo': AppRoute.settings.path}),
    );
    void editProfile() => context.push(AppRoute.editProfile.path);
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoute.profile.path);
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: const Text('Cài đặt'),
          leading: IconButton(
            tooltip: 'Quay lại hồ sơ cá nhân',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoute.profile.path),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.margin),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: context.colors.primaryContainer,
                child: Icon(
                  Icons.tune,
                  size: 20,
                  color: context.colors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            key: const PageStorageKey('settings-scroll'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.md,
              AppSpacing.margin,
              AppSpacing.xl,
            ),
            children: [
              if (session.isLoading)
                LinearProgressIndicator(
                  value: MediaQuery.disableAnimationsOf(context) ? 0 : null,
                ),
              if (session.hasError)
                AppErrorState(
                  message: AppErrorMessage.from(
                    session.error!,
                    fallback: 'Không kiểm tra được phiên đăng nhập.',
                  ),
                  onRetry: () => ref.invalidate(authSessionProvider),
                ),
              Material(
                color: context.colors.surface,
                borderRadius: AppRadii.inputBorder,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: session.isLoading || session.hasError
                      ? null
                      : user == null
                      ? login
                      : editProfile,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: user?.displayName ?? 'Khách',
                          imageUrl: user?.photoUrl,
                          size: AppAvatarSize.large,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Chào bạn!',
                                style: context.textStyles.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                user == null
                                    ? 'Đăng nhập để quản lý tài khoản'
                                    : 'Thông tin tài khoản',
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: context.colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsSection(
                title: 'Tài khoản',
                children: [
                  SettingsRow(
                    icon: Icons.person_outline,
                    title: 'Chỉnh sửa hồ sơ',
                    subtitle: user == null
                        ? 'Cần đăng nhập để cập nhật hồ sơ'
                        : 'Cập nhật tên và ảnh đại diện',
                    onTap: user == null ? null : editProfile,
                  ),
                  SettingsRow(
                    icon: Icons.lock_outline,
                    title: 'Đặt lại mật khẩu',
                    subtitle: 'Nhận liên kết qua email đã đăng ký',
                    onTap: () => context.push(AppRoute.forgotPassword.path),
                  ),
                  const SettingsRow(
                    icon: Icons.security_outlined,
                    title: 'Quyền riêng tư',
                    subtitle: 'Chưa hỗ trợ quản lý quyền hiển thị',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SettingsSection(
                title: 'Giao diện',
                children: [
                  SettingsRow(
                    icon: Icons.palette_outlined,
                    title: 'Chế độ hiển thị',
                    subtitle: '${modeLabel(mode)} • Lưu trong phiên hiện tại',
                    onTap: () => _chooseTheme(context, ref),
                    trailing: Icon(
                      switch (mode) {
                        ThemeMode.system => Icons.brightness_auto_outlined,
                        ThemeMode.light => Icons.light_mode_outlined,
                        ThemeMode.dark => Icons.dark_mode_outlined,
                      },
                      color: context.colors.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SettingsSection(
                title: 'Hỗ trợ',
                children: [
                  SettingsRow(
                    icon: Icons.help_outline,
                    title: 'Trung tâm trợ giúp',
                    subtitle: 'Chưa có nội dung hướng dẫn',
                  ),
                  SettingsRow(
                    icon: Icons.description_outlined,
                    title: 'Điều khoản sử dụng',
                    subtitle: 'Chưa có tài liệu được công bố',
                  ),
                  SettingsRow(
                    icon: Icons.policy_outlined,
                    title: 'Chính sách quyền riêng tư',
                    subtitle: 'Chưa có tài liệu được công bố',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (user != null) const SignOutAction(),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant,
                    color: context.colors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'Food Review Vietnam',
                      style: context.textStyles.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Đồng hành cùng ẩm thực Việt mỗi ngày • Tôn vinh hương vị phố phường',
                textAlign: TextAlign.center,
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
