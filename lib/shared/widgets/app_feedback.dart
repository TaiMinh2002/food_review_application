import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_button.dart';

enum AppFeedbackType { success, error, warning, info }

abstract final class AppToast {
  static void show(
    BuildContext context,
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
  }) {
    final (color, foreground, icon) = switch (type) {
      AppFeedbackType.success => (
        context.semanticColors.success,
        context.semanticColors.onSuccess,
        Icons.check_circle_outline,
      ),
      AppFeedbackType.error => (
        context.colors.error,
        context.colors.onError,
        Icons.error_outline,
      ),
      AppFeedbackType.warning => (
        context.semanticColors.warning,
        context.semanticColors.onWarning,
        Icons.warning_amber_rounded,
      ),
      AppFeedbackType.info => (
        context.colors.inverseSurface,
        context.colors.onInverseSurface,
        Icons.info_outline,
      ),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          showCloseIcon: true,
          closeIconColor: foreground,
          content: Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.bookmark_border,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? message, actionLabel;
  final IconData icon;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: context.colors.surfaceContainerLow,
            child: Icon(icon, size: 32, color: context.colors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textStyles.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 16),
            AppButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    ),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Không thể tải dữ liệu',
    this.message = 'Vui lòng kiểm tra lại kết nối mạng.',
    this.onRetry,
  });
  final String title, message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: AppSpacing.page,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.errorContainer,
          borderRadius: AppRadii.inputBorder,
          border: Border.all(color: context.colors.error.withValues(alpha: .3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_off, color: context.colors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: context.textStyles.titleMedium?.copyWith(
                        color: context.colors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onErrorContainer,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Thử lại',
                  onPressed: onRetry,
                  variant: AppButtonVariant.destructive,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
