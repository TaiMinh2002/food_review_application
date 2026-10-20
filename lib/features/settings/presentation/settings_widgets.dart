import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.xs,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          title.toUpperCase(),
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
      ),
      Material(
        color: context.colors.surface,
        borderRadius: AppRadii.inputBorder,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Divider(height: 1),
                ),
              children[index],
            ],
          ],
        ),
      ),
    ],
  );
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Semantics(
    enabled: onTap != null,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadii.small),
              ),
              child: Icon(
                icon,
                size: 22,
                color: onTap != null
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textStyles.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: context.colors.onSurfaceVariant,
              ),
          ],
        ),
      ),
    ),
  );
}
