import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/place.dart';
import '../domain/place_menu_item.dart';

Future<void> showPlaceShare(
  BuildContext context,
  Place place, {
  String? location,
}) => showAppBottomSheet<void>(
  context,
  title: 'Chia sẻ quán',
  builder: (sheetContext) {
    final info =
        '${place.name}\n${place.address}\n${location ?? AppRoute.restaurant.location(parameters: {'restaurantId': place.id})}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SelectableText(info),
        const SizedBox(height: 12),
        Text(
          'Sao chép thông tin và đường dẫn nội bộ. Chia sẻ qua ứng dụng khác chưa tích hợp.',
          style: sheetContext.textStyles.bodySmall,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Sao chép thông tin',
          icon: Icons.copy_outlined,
          onPressed: () async {
            try {
              await Clipboard.setData(ClipboardData(text: info));
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              if (context.mounted) {
                AppToast.show(context, 'Đã sao chép thông tin quán.');
              }
            } on PlatformException {
              if (sheetContext.mounted) {
                AppToast.show(
                  sheetContext,
                  'Không thể sao chép. Vui lòng thử lại.',
                  type: AppFeedbackType.error,
                );
              }
            }
          },
        ),
      ],
    );
  },
);

Future<void> showPlaceContact(BuildContext context) => showAppBottomSheet<void>(
  context,
  title: 'Liên hệ quán',
  builder: (context) => const Text(
    'Chưa có số điện thoại được xác minh. Chức năng gọi điện sẽ khả dụng khi có dữ liệu liên hệ.',
  ),
);

Future<void> showPlaceMenu(BuildContext context, Place place) =>
    showAppBottomSheet<void>(
      context,
      title: place.isDemo ? 'Thực đơn minh họa' : 'Thực đơn',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Thông tin tham khảo. Ứng dụng chưa hỗ trợ đặt món.'),
          for (final item in place.menuItems)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text(item.description),
              trailing: Text(
                AppFormatters.price(item.price),
                style: context.textStyles.labelMedium,
              ),
            ),
        ],
      ),
    );

Future<void> showPlaceDish(
  BuildContext context,
  PlaceMenuItem item, {
  required bool isDemo,
}) => showAppBottomSheet<void>(
  context,
  title: item.name,
  builder: (context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: AppRadii.inputBorder,
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: AppImage(url: item.imageUrl),
        ),
      ),
      const SizedBox(height: 12),
      Text(item.description),
      const SizedBox(height: 8),
      Text(
        AppFormatters.price(item.price),
        style: context.textStyles.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(
        isDemo
            ? 'Món và giá minh họa · Không hỗ trợ đặt món.'
            : 'Giá tham khảo · Không hỗ trợ đặt món.',
        style: context.textStyles.bodySmall,
      ),
    ],
  ),
);
