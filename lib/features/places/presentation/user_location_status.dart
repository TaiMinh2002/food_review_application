import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design_system/design_system.dart';
import 'user_location_controller.dart';

class UserLocationStatus extends ConsumerWidget {
  const UserLocationStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userLocationControllerProvider);
    final controller = ref.read(userLocationControllerProvider.notifier);
    final point = state.point;
    final label = state.locating
        ? 'Đang lấy vị trí hiện tại…'
        : point != null
        ? 'Vị trí hiện tại · ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}'
        : 'Chưa có vị trí hiện tại';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, size: 18, color: context.colors.secondary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ),
            if (state.locating)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Cập nhật vị trí',
                onPressed: controller.locate,
                icon: const Icon(Icons.my_location, size: 20),
              ),
          ],
        ),
        if (state.error != null) ...[
          Text(state.error!, style: context.textStyles.bodySmall),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: controller.locate,
                child: const Text('Thử lại'),
              ),
              TextButton(
                onPressed: () async {
                  final opened = await controller.openSettings();
                  if (context.mounted && !opened) {
                    AppToast.show(
                      context,
                      'Vui lòng mở Cài đặt thiết bị để cấp quyền vị trí.',
                    );
                  }
                },
                child: const Text('Cài đặt vị trí'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
