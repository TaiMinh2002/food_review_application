import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../core/errors/app_error_message.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final user = session.asData?.value;
    final logout = ref.watch(signOutControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: AppAvatar(
              name: user?.displayName ?? 'Chào bạn',
              imageUrl: user?.photoUrl,
              size: AppAvatarSize.large,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            user == null ? 'Chào bạn!' : 'Chào ${user.displayName}!',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            user == null ? 'Đăng nhập để quản lý nội dung và quán đã lưu.' : 'Bạn đã đăng nhập. Danh sách quán hiện dùng dữ liệu mẫu; yêu thích chỉ lưu trong phiên, chưa đồng bộ máy chủ.',
          ),
          if (session.isLoading) const LinearProgressIndicator(),
          if (session.hasError)
            AppErrorState(
              message: AppErrorMessage.from(
                session.error!,
                fallback: 'Không kiểm tra được phiên đăng nhập.',
              ),
              onRetry: () => ref.invalidate(authSessionProvider),
            ),
          if (logout.hasError)
            Text(
              AppErrorMessage.from(
                logout.error!,
                fallback: 'Không đăng xuất được. Vui lòng thử lại.',
              ),
            ),
          const SizedBox(height: 24),
          if (user != null) ...[
            AppButton(
              label: 'Đánh giá của tôi',
              icon: Icons.rate_review_outlined,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: () => context.push(AppRoute.myReviews.path),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Muốn ghé thăm',
              icon: Icons.bookmark_border,
              variant: AppButtonVariant.secondary,
              expanded: true,
              onPressed: () => context.push(AppRoute.wantToVisit.path),
            ),
            const SizedBox(height: 12),
          ],
          AppButton(
            variant: AppButtonVariant.outline,
            label: user == null ? 'Đăng nhập' : 'Đăng xuất',
            isLoading: logout.isLoading,
            onPressed: session.isLoading || session.hasError
                ? null
                : () {
                    if (user == null) {
                      context.push(
                        AppRoute.login.location(
                          query: {'returnTo': AppRoute.profile.path},
                        ),
                      );
                    } else {
                      ref.read(signOutControllerProvider.notifier).submit();
                    }
                  },
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 16),
          AppButton(
            label: 'Xem UI Kit',
            variant: AppButtonVariant.outline,
            icon: Icons.palette_outlined,
            onPressed: () => context.push('/design-system'),
          ),
        ],
      ),
    );
  }
}
