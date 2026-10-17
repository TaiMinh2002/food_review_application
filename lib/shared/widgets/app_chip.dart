import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.icon,
    this.showCheckmark = false,
  });
  final String label;
  final bool selected, showCheckmark;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: showCheckmark,
    checkmarkColor: context.colors.onPrimary,
    avatar: icon == null
        ? null
        : Icon(
            icon,
            size: 16,
            color: selected
                ? context.colors.onPrimary
                : context.colors.onSurfaceVariant,
          ),
    labelStyle: context.textStyles.labelMedium?.copyWith(
      color: selected ? context.colors.onPrimary : context.colors.onSurface,
    ),
  );
}

enum AppBadgeTone { neutral, primary, accent, success, warning, error }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  });
  final String label;
  final AppBadgeTone tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      AppBadgeTone.neutral => (
        context.colors.surfaceContainerLow,
        context.colors.onSurfaceVariant,
      ),
      AppBadgeTone.primary => (
        context.colors.primaryContainer,
        context.colors.onPrimaryContainer,
      ),
      AppBadgeTone.accent => (
        context.colors.secondaryContainer,
        context.colors.onSecondaryContainer,
      ),
      AppBadgeTone.success => (
        context.semanticColors.successContainer,
        context.semanticColors.success,
      ),
      AppBadgeTone.warning => (
        context.semanticColors.warningContainer,
        context.semanticColors.warning,
      ),
      AppBadgeTone.error => (
        context.colors.errorContainer,
        context.colors.onErrorContainer,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: context.textStyles.labelSmall?.copyWith(
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
