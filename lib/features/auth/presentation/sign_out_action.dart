import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import 'auth_providers.dart';

/// Shared by Profile and Settings so both exits require confirmation.
class SignOutAction extends ConsumerStatefulWidget {
  const SignOutAction({super.key});

  @override
  ConsumerState<SignOutAction> createState() => _SignOutActionState();
}

class _SignOutActionState extends ConsumerState<SignOutAction> {
  bool _confirming = false;

  Future<void> _signOut() async {
    if (_confirming) return;
    final owner = ref.read(authSessionProvider).asData?.value?.id;
    if (owner == null) return;
    setState(() => _confirming = true);
    final confirmed = await showAppConfirmation(
      context,
      title: 'Đăng xuất khỏi tài khoản?',
      message:
          'Bạn sẽ trở về chế độ khách. Các bản nháp chưa lưu sẽ bị bỏ. '
          'Đánh giá đã đăng không bị xóa.',
      confirmLabel: 'Đăng xuất',
      destructive: true,
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    // Never sign out a different account if the session changed in the dialog.
    final session = ref.read(authSessionProvider);
    if (!confirmed ||
        session.isLoading ||
        session.hasError ||
        session.asData?.value?.id != owner) {
      return;
    }
    final router = GoRouter.of(context);
    final success = await ref.read(signOutControllerProvider.notifier).submit();
    if (!success) return;
    // Auth can remove this widget before signOut completes. The app-owned router
    // still replaces the stack, so Back cannot restore private forms/drafts.
    router.go(AppRoute.profile.path);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final state = ref.watch(signOutControllerProvider);
    if (session.isLoading ||
        session.hasError ||
        session.asData?.value == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.errorContainer.withValues(
              alpha: .4,
            ),
            foregroundColor: context.colors.error,
            padding: const EdgeInsets.all(AppSpacing.md),
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.inputBorder,
            ),
          ),
          onPressed: _confirming || state.isLoading ? null : _signOut,
          icon: state.isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout, size: 20),
          label: Text(state.isLoading ? 'Đang đăng xuất…' : 'Đăng xuất'),
        ),
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              AppErrorMessage.from(
                state.error!,
                fallback: 'Không đăng xuất được. Vui lòng thử lại.',
              ),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ),
      ],
    );
  }
}
