import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

enum AppButtonVariant { primary, secondary, outline, text, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading, expanded;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final foreground = switch (variant) {
      AppButtonVariant.primary => context.colors.onPrimary,
      AppButtonVariant.destructive => context.colors.onError,
      _ => context.colors.primary,
    };
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
              semanticsLabel: 'Đang xử lý',
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            isLoading ? 'Đang xử lý...' : label,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    final loadingStyle = isLoading
        ? ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(switch (variant) {
              AppButtonVariant.primary => context.colors.primary,
              AppButtonVariant.destructive => context.colors.error,
              _ => context.colors.primaryContainer,
            }),
            foregroundColor: WidgetStatePropertyAll(foreground),
          )
        : null;
    final Widget button = switch (variant) {
      AppButtonVariant.outline => OutlinedButton(
        onPressed: callback,
        style: loadingStyle,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: callback,
        style: loadingStyle,
        child: child,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: callback,
        style: (loadingStyle ?? const ButtonStyle()).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => !isLoading && states.contains(WidgetState.disabled)
                ? context.colors.onSurface.withValues(alpha: .12)
                : context.colors.primaryContainer,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => !isLoading && states.contains(WidgetState.disabled)
                ? context.colors.onSurface.withValues(alpha: .38)
                : context.colors.onPrimaryContainer,
          ),
        ),
        child: child,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: callback,
        style:
            loadingStyle ??
            FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
        child: child,
      ),
      AppButtonVariant.primary => FilledButton(
        onPressed: callback,
        style: loadingStyle,
        child: child,
      ),
    };
    return Semantics(
      liveRegion: isLoading,
      child: expanded
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
    this.circular = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected, circular;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    style: IconButton.styleFrom(
      backgroundColor: context.colors.surfaceContainerLow,
      foregroundColor: selected
          ? context.colors.error
          : context.colors.onSurface,
      shape: circular
          ? const CircleBorder()
          : const RoundedRectangleBorder(borderRadius: AppRadii.inputBorder),
    ),
  );
}
