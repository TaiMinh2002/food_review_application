import 'package:flutter/material.dart';

import 'app_feedback.dart';

/// Compatibility facade for existing screens. New screens may use the explicit
/// empty/error components directly.
class AppMessage extends StatelessWidget {
  const AppMessage({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => onRetry != null
      ? Center(
          child: AppErrorState(message: message, onRetry: onRetry),
        )
      : AppEmptyState(title: message);
}
