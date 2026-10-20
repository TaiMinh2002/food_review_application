import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/memory_want_to_visit_repository.dart';
import '../domain/want_to_visit_repository.dart';

final wantToVisitRepositoryProvider = Provider<WantToVisitRepository>((ref) {
  ref.watch(authSessionProvider.select((state) => state.asData?.value?.id));
  final repository = MemoryWantToVisitRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final wantToVisitIdsProvider = NotifierProvider<WantToVisitIds, Set<String>>(
  WantToVisitIds.new,
);

class WantToVisitIds extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final session = ref.watch(authSessionProvider);
    final user = session.asData?.value;
    if (session.isLoading || session.hasError || user == null) return {};
    final repository = ref.watch(wantToVisitRepositoryProvider);
    final subscription = repository.watchPlaceIds(user.id).listen((ids) {
      if (ref.mounted) state = Set.unmodifiable(ids);
    });
    ref.onDispose(subscription.cancel);
    return {};
  }

  void toggle(String placeId) {
    final session = ref.read(authSessionProvider);
    if (session.isLoading ||
        session.hasError ||
        session.asData?.value == null) {
      throw const AppException('Vui lòng đăng nhập trước khi thêm danh sách.');
    }
    final user = session.asData!.value!;
    final repository = ref.read(wantToVisitRepositoryProvider);
    final previous = state;
    final value = !state.contains(placeId);
    final next = {...state};
    if (value) {
      next.add(placeId);
    } else {
      next.remove(placeId);
    }
    state = Set.unmodifiable(next);
    unawaited(
      repository
          .setWantToVisit(userId: user.id, placeId: placeId, value: value)
          .catchError((_) {
            if (ref.mounted) state = previous;
          }),
    );
  }
}

void requestWantToVisit(BuildContext context, WidgetRef ref, String placeId) {
  final session = ref.read(authSessionProvider);
  if (session.isLoading || session.hasError) {
    AppToast.show(
      context,
      'Chưa kiểm tra được phiên đăng nhập. Vui lòng thử lại.',
    );
  } else if (session.asData?.value == null) {
    context.push(
      AppRoute.login.location(
        query: {
          'returnTo': AppRoute.restaurant.location(
            parameters: {'restaurantId': placeId},
          ),
          'action': 'want_to_visit',
        },
      ),
    );
  } else {
    ref.read(wantToVisitIdsProvider.notifier).toggle(placeId);
  }
}
