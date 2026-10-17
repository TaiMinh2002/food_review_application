import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel = 'Xem tất cả',
    this.onAction,
  });
  final String title, actionLabel;
  final String? subtitle;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.headlineSmall),
        if (subtitle != null)
          Text(
            subtitle!,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    );
    final action = onAction == null
        ? null
        : TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(actionLabel),
          );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (action == null) return heading;
        if (constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, action],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 8),
            Flexible(
              child: Align(alignment: Alignment.centerRight, child: action),
            ),
          ],
        );
      },
    );
  }
}
