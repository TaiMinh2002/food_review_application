import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import 'auth_providers.dart';

/// No private content is built before the persisted-session event arrives.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child, required this.returnTo});
  final Widget child;
  final String returnTo;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: context.semanticColors.canvas,
    child: ref
        .watch(authSessionProvider)
        .when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const SafeArea(
            child: Padding(
              padding: AppSpacing.page,
              child: AppSkeleton(height: 180),
            ),
          ),
          error: (error, _) => AppErrorState(
            message: AppErrorMessage.from(
              error,
              fallback: 'Không kiểm tra được phiên đăng nhập.',
            ),
            onRetry: () => ref.invalidate(authSessionProvider),
          ),
          data: (user) => user == null
              ? AppEmptyState(
                  title: 'Đăng nhập để tiếp tục',
                  message:
                      'Tài khoản giúp bạn quản lý nội dung và quán đã lưu.',
                  actionLabel: 'Đăng nhập',
                  onAction: () => context.push(
                    AppRoute.login.location(query: {'returnTo': returnTo}),
                  ),
                )
              : child,
        ),
  );
}
