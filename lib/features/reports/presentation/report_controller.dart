import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../places/presentation/map_controller.dart';
import '../../places/presentation/place_providers.dart';
import '../../reviews/presentation/review_providers.dart';
import '../data/demo_report_repository.dart';
import '../data/firestore_report_repository.dart';
import '../domain/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    return DemoReportRepository(
      places: ref.watch(placeRepositoryProvider),
      reviews: ref.watch(reviewRepositoryProvider),
    );
  }
  return FirestoreReportRepository(
    FirebaseFirestore.instance,
    places: ref.watch(placeRepositoryProvider),
    reviews: ref.watch(reviewRepositoryProvider),
    osmPlaces: ref.watch(osmRegionPlaceRepositoryProvider),
  );
});

typedef ReportKey = ({String ownerId, String scope, ReportTarget target});

final reportTargetProvider = FutureProvider.autoDispose
    .family<ReportContext?, ReportKey>((ref, key) async {
      final value = await ref
          .watch(reportRepositoryProvider)
          .getTarget(key.target, reporterId: key.ownerId);
      if (value != null && value.target != key.target) {
        throw const AppException('Không đọc được nội dung cần báo cáo.');
      }
      return value;
    }, retry: (_, _) => null);

final reportSubmitProvider = NotifierProvider.autoDispose
    .family<ReportSubmitController, AsyncValue<ReportReceipt?>, ReportKey>(
      ReportSubmitController.new,
    );

class ReportSubmitController extends Notifier<AsyncValue<ReportReceipt?>> {
  ReportSubmitController(this.key);
  final ReportKey key;
  late final String _requestId =
      'report-${DateTime.now().microsecondsSinceEpoch}-${key.scope}';
  @override
  AsyncValue<ReportReceipt?> build() => const AsyncData(null);
  bool get sameSession {
    final session = ref.read(authSessionProvider);
    return !session.isLoading &&
        !session.hasError &&
        session.asData?.value?.id == key.ownerId;
  }

  Future<ReportReceipt?> submit(ReportDraft draft) async {
    if (state.isLoading || state.asData?.value != null || !sameSession) {
      return null;
    }
    state = const AsyncLoading();
    try {
      if (draft.target != key.target) {
        throw const AppException(
          'Nội dung báo cáo đã thay đổi. Vui lòng mở lại form.',
        );
      }
      final error = draft.validationError;
      if (error != null) throw AppException(error);
      final receipt = await ref
          .read(reportRepositoryProvider)
          .submit(reporterId: key.ownerId, requestId: _requestId, draft: draft);
      if (!ref.mounted || !sameSession) return null;
      state = AsyncData(receipt);
      return receipt;
    } catch (error, stack) {
      if (ref.mounted && sameSession) state = AsyncError(error, stack);
      return null;
    }
  }
}
