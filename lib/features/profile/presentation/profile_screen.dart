import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/sign_out_action.dart';
import '../domain/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final user = session.asData?.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá Nhân'),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            icon: const Icon(Icons.notifications_none),
            onPressed: user == null
                ? null
                : () => context.push(AppRoute.notifications.path),
          ),
          IconButton(
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoute.settings.path),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          key: const PageStorageKey('profile-scroll'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margin,
            AppSpacing.md,
            AppSpacing.margin,
            AppSpacing.xxl,
          ),
          children: [
            if (session.isLoading) const LinearProgressIndicator(),
            if (session.hasError)
              AppErrorState(
                message: AppErrorMessage.from(
                  session.error!,
                  fallback: 'Không kiểm tra được phiên đăng nhập.',
                ),
                onRetry: () => ref.invalidate(authSessionProvider),
              ),
            _ProfileHeader(user: user),
            const SizedBox(height: AppSpacing.lg),
            if (user == null)
              _GuestPanel(
                onLogin: () => context.push(
                  AppRoute.login.location(
                    query: {'returnTo': AppRoute.profile.path},
                  ),
                ),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoute.editProfile.path),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Chỉnh sửa hồ sơ'),
              ),
              const SizedBox(height: AppSpacing.sm),
              const SignOutAction(),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Hoạt động của tôi'),
              const SizedBox(height: AppSpacing.sm),
              _ActivityCard(onWrite: () => context.go(AppRoute.home.path)),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Danh mục cá nhân'),
              const SizedBox(height: AppSpacing.sm),
              _ProfileMenuCard(
                items: [
                  _ProfileMenuItem(
                    icon: Icons.star_border,
                    title: 'Đánh giá của tôi',
                    subtitle: 'Xem và chỉnh sửa các đánh giá đã đăng',
                    onTap: () => context.push(AppRoute.myReviews.path),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.favorite_border,
                    title: 'Nhà hàng yêu thích',
                    subtitle: 'Những địa điểm bạn đã lưu',
                    onTap: () => context.go(AppRoute.favorites.path),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.bookmark_border,
                    title: 'Danh sách muốn đến',
                    subtitle: 'Những nơi bạn dự định trải nghiệm',
                    onTap: () => context.push(AppRoute.wantToVisit.path),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.collections_bookmark_outlined,
                    title: 'Bộ sưu tập',
                    subtitle: 'Sắp xếp địa điểm theo chủ đề',
                    onTap: () => context.go(AppRoute.collections.path),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.notifications_none,
                    title: 'Thông báo',
                    subtitle: 'Cập nhật hoạt động của bạn',
                    badge: '2',
                    onTap: () => context.push(AppRoute.notifications.path),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle('Tài khoản & Hỗ trợ'),
              const SizedBox(height: AppSpacing.sm),
              _ProfileMenuCard(
                items: [
                  _ProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Cài đặt tài khoản',
                    subtitle: 'Quản lý tùy chọn ứng dụng',
                    onTap: () => context.push(AppRoute.settings.path),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.help_outline,
                    title: 'Trợ giúp và góp ý',
                    subtitle: 'Gửi câu hỏi hoặc phản hồi',
                    onTap: () =>
                        _showMessage(context, 'Trợ giúp sẽ được bổ sung sau.'),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.policy_outlined,
                    title: 'Chính sách quyền riêng tư',
                    subtitle: 'Thông tin sử dụng dữ liệu',
                    onTap: () => _showMessage(
                      context,
                      'Chính sách sẽ được bổ sung sau.',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Ẩm Thực Việt • Phiên bản 2.4.1\nTôn vinh hương vị phố phường',
              textAlign: TextAlign.center,
              style: context.textStyles.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName ?? 'Chào bạn';
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            AppAvatar(
              name: name,
              imageUrl: user?.photoUrl,
              size: AppAvatarSize.large,
            ),
            if (user != null)
              IconButton.filled(
                tooltip: 'Sửa ảnh đại diện',
                onPressed: () => context.push(AppRoute.editProfile.path),
                style: IconButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                ),
                icon: const Icon(Icons.camera_alt, size: 18),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(name, style: context.textStyles.headlineSmall),
        if (user != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chào ${user!.displayName}!',
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '@${user!.id}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '“Khám phá món ngon, chia sẻ trải nghiệm.”',
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const _ProfileStats(),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Đăng nhập để quản lý đánh giá và danh sách cá nhân.',
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _Metric(value: '—', label: 'Đánh giá'),
      _Metric(value: '—', label: 'Đang theo dõi'),
      _Metric(value: '—', label: 'Người theo dõi'),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: context.textStyles.titleLarge),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) =>
      Text(title, style: context.textStyles.titleMedium);
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.onWrite});
  final VoidCallback onWrite;
  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.rate_review_outlined, color: context.colors.primary),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chia sẻ trải nghiệm của bạn'),
                SizedBox(height: 4),
                Text('Đánh giá chân thực giúp cộng đồng tìm được quán ngon.'),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Viết đánh giá',
            onPressed: onWrite,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    ),
  );
}

class _GuestPanel extends StatelessWidget {
  const _GuestPanel({required this.onLogin});
  final VoidCallback onLogin;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.person_outline, size: 36),
          const SizedBox(height: AppSpacing.sm),
          const Text('Đăng nhập để tiếp tục'),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Lưu quán, viết đánh giá và quản lý danh sách cá nhân.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'Đăng nhập', expanded: true, onPressed: onLogin),
        ],
      ),
    ),
  );
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.items});
  final List<_ProfileMenuItem> items;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _ProfileMenuTile(item: items[index]),
          if (index < items.length - 1)
            Divider(height: 1, color: context.colors.outlineVariant),
        ],
      ],
    ),
  );
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  final String? badge;
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.item});
  final _ProfileMenuItem item;
  @override
  Widget build(BuildContext context) {
    final color = context.colors.onSurface;
    return ListTile(
      enabled: item.onTap != null,
      leading: Icon(item.icon, color: context.colors.primary),
      title: Text(
        item.title,
        style: context.textStyles.bodyMedium?.copyWith(color: color),
      ),
      subtitle: Text(item.subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.badge != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppBadge(label: item.badge!, tone: AppBadgeTone.warning),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: item.onTap,
    );
  }
}
