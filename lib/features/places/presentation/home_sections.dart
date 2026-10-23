import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';
import 'user_location_status.dart';

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const UserLocationStatus(),
      const SizedBox(height: AppSpacing.xs),
      Text('Hôm nay ăn gì?', style: context.textStyles.headlineLarge),
      Text(
        'Khám phá quán ăn trong khu vực bạn chọn',
        style: context.textStyles.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
