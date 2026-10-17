import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: AppAvatar(name: 'Chào bạn', size: AppAvatarSize.large),
          ),
          const SizedBox(height: 24),
          const Text('Chào bạn!', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'Hiện đang dùng bản demo. Đăng nhập và review cá nhân sẽ được bổ sung khi kết nối Firebase.',
          ),
          const SizedBox(height: 24),
          AppButton(
            variant: AppButtonVariant.outline,
            label: 'Thông tin đăng nhập',
            onPressed: () => context.push(AppRoute.login.path),
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
