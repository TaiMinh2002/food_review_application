import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_button.dart';

Future<bool> showAppConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xác nhận',
  String cancelLabel = 'Huỷ',
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          destructive ? Icons.delete_outline : Icons.help_outline,
          color: destructive ? context.colors.error : context.colors.primary,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton(
            label: cancelLabel,
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.pop(context, false),
          ),
          AppButton(
            label: confirmLabel,
            variant: destructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
    false;

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  String? actionLabel,
  VoidCallback? onAction,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: context.textStyles.headlineSmall),
                ),
                if (onAction != null && actionLabel != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
            const SizedBox(height: 16),
            builder(context),
          ],
        ),
      ),
    ),
  ),
);
