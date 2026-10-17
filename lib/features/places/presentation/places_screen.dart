import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_message.dart';
import '../../../core/errors/app_error_message.dart';
import '../../../shared/design_system/design_system.dart';
import 'place_card.dart';
import 'place_providers.dart';

class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Khám phá quán ngon')),
      body: ref
          .watch(placesProvider)
          .when(
            loading: () => ListView(
              padding: AppSpacing.page,
              children: const [
                AppRestaurantSkeleton(),
                SizedBox(height: 12),
                AppRestaurantSkeleton(),
              ],
            ),
            error: (error, stack) => AppMessage(
              message: AppErrorMessage.from(
                error,
                fallback: 'Không tải được danh sách quán.',
              ),
              onRetry: () => ref.invalidate(placesProvider),
            ),
            data: (places) {
              final filtered = filterPlaces(places, _query, _category);
              final categories = places.map((place) => place.category).toSet();
              return ListView(
                padding: AppSpacing.page,
                children: [
                  Text(
                    'Hôm nay bạn muốn ăn gì?',
                    style: context.textStyles.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bản demo · Địa điểm minh họa · Yêu thích lưu trong phiên',
                  ),
                  const SizedBox(height: 20),
                  AppSearchField(
                    hintText: 'Tìm theo tên quán',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      AppChip(
                        label: 'Tất cả',
                        selected: _category == null,
                        onSelected: (_) => setState(() => _category = null),
                      ),
                      for (final category in categories)
                        AppChip(
                          label: category,
                          selected: _category == category,
                          onSelected: (selected) => setState(
                            () => _category = selected ? category : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty)
                    const AppMessage(message: 'Không tìm thấy quán phù hợp.'),
                  for (final place in filtered) PlaceCard(place: place),
                ],
              );
            },
          ),
    );
  }
}
