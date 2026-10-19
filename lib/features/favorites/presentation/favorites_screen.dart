import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_message.dart';
import '../../../core/errors/app_error_message.dart';
import '../../places/presentation/place_card.dart';
import '../../places/presentation/place_providers.dart';
import 'favorite_providers.dart';
import '../../auth/presentation/auth_gate.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoriteIdsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Quán đã lưu')),
      body: AuthGate(
        returnTo: '/favorites',
        child: ref
            .watch(placesProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => AppMessage(
                message: AppErrorMessage.from(
                  error,
                  fallback: 'Không tải được quán đã lưu.',
                ),
                onRetry: () => ref.invalidate(placesProvider),
              ),
              data: (places) {
                final favorites = places
                    .where((place) => ids.contains(place.id))
                    .toList();
                if (favorites.isEmpty) {
                  return const AppMessage(
                    message: 'Bạn chưa lưu quán nào. Khám phá và chạm biểu tượng trái tim để lưu.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) =>
                      PlaceCard(place: favorites[index]),
                );
              },
            ),
      ),
    );
  }
}
