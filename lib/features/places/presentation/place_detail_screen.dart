import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_message.dart';
import '../../../core/errors/app_error_message.dart';
import '../../../shared/design_system/design_system.dart';
import '../../favorites/presentation/favorite_providers.dart';
import 'place_providers.dart';

class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = ref.watch(favoriteIdsProvider).contains(placeId);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết quán')),
      body: ref
          .watch(placeProvider(placeId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => AppMessage(
              message: AppErrorMessage.from(
                error,
                fallback: 'Không tải được thông tin quán.',
              ),
              onRetry: () => ref.invalidate(placeProvider(placeId)),
            ),
            data: (place) {
              if (place == null) {
                return const AppMessage(message: 'Quán không tồn tại.');
              }
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.restaurant_menu, size: 80),
                  const SizedBox(height: 24),
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(place.category),
                  const SizedBox(height: 16),
                  Text(place.description),
                  const SizedBox(height: 16),
                  Text(place.address),
                  const SizedBox(height: 16),
                  Text(
                    place.reviewCount == 0
                        ? 'Chưa có đánh giá'
                        : '★ ${place.averageRating.toStringAsFixed(1)} · ${place.reviewCount} đánh giá',
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    onPressed: () =>
                        ref.read(favoriteIdsProvider.notifier).toggle(placeId),
                    icon: favorite ? Icons.favorite : Icons.favorite_border,
                    label: favorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Review, ảnh và bản đồ sẽ được kết nối ở giai đoạn tiếp theo.',
                  ),
                ],
              );
            },
          ),
    );
  }
}
