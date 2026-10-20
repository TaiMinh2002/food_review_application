import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/demo_notification_repository.dart';
import '../domain/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => DemoNotificationRepository(),
);

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.total = 0,
    this.loading = true,
    this.loadingMore = false,
    this.refreshing = false,
    this.nextCursor,
    this.error,
    this.pageError,
    this.isDemo = false,
  });
  final List<AppNotification> items;
  final int total;
  final bool loading, loadingMore, refreshing, isDemo;
  final String? nextCursor, error, pageError;
  int get unreadCount => items.where((item) => !item.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? total,
    bool? loading,
    bool? loadingMore,
    bool? refreshing,
    String? nextCursor,
    bool clearCursor = false,
    String? error,
    String? pageError,
    bool? isDemo,
  }) => NotificationsState(
    items: items ?? this.items,
    total: total ?? this.total,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    refreshing: refreshing ?? this.refreshing,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    error: error,
    pageError: pageError,
    isDemo: isDemo ?? this.isDemo,
  );
}

final notificationsControllerProvider =
    NotifierProvider.autoDispose<NotificationsController, NotificationsState>(
      NotificationsController.new,
    );

class NotificationsController extends Notifier<NotificationsState> {
  int _generation = 0;
  String? _recipientId;
  late NotificationRepository _repository;

  @override
  NotificationsState build() {
    final session = ref.watch(authSessionProvider);
    _recipientId = session.isLoading || session.hasError
        ? null
        : session.asData?.value?.id;
    _repository = ref.watch(notificationRepositoryProvider);
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    if (_recipientId != null) {
      scheduleMicrotask(() {
        if (ref.mounted && generation == _generation) refresh();
      });
    }
    return const NotificationsState();
  }

  Future<void> refresh() async {
    final recipientId = _recipientId;
    if (recipientId == null) return;
    final generation = ++_generation;
    final old = state;
    state = NotificationsState(
      items: old.items,
      total: old.total,
      loading: old.items.isEmpty,
      refreshing: old.items.isNotEmpty,
      isDemo: old.isDemo,
    );
    try {
      final page = await _repository.getNotifications(recipientId: recipientId);
      if (!ref.mounted || generation != _generation) return;
      _validate(page, recipientId);
      state = NotificationsState(
        items: page.items,
        total: page.total,
        loading: false,
        nextCursor: page.nextCursor,
        isDemo: page.isDemo,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = NotificationsState(
        items: old.items,
        total: old.total,
        loading: false,
        isDemo: old.isDemo,
        error: AppErrorMessage.from(
          error,
          fallback: 'Không tải được thông báo. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final old = state;
    final recipientId = _recipientId;
    final cursor = old.nextCursor;
    if (recipientId == null ||
        cursor == null ||
        old.loading ||
        old.refreshing ||
        old.loadingMore) {
      return;
    }
    final generation = _generation;
    state = old.copyWith(loadingMore: true, pageError: null);
    try {
      final page = await _repository.getNotifications(
        recipientId: recipientId,
        cursor: cursor,
      );
      if (!ref.mounted || generation != _generation) return;
      _validate(page, recipientId);
      if (page.items.any(
            (item) => old.items.any((existing) => existing.id == item.id),
          ) ||
          page.nextCursor == cursor ||
          page.total != old.total ||
          old.items.length + page.items.length > page.total) {
        throw const AppException(
          'Danh sách thông báo đã thay đổi. Vui lòng tải lại.',
        );
      }
      state = NotificationsState(
        items: List.unmodifiable([...old.items, ...page.items]),
        total: page.total,
        loading: false,
        nextCursor: page.nextCursor,
        isDemo: page.isDemo,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = old.copyWith(
        loadingMore: false,
        pageError: AppErrorMessage.from(
          error,
          fallback: 'Không tải thêm được thông báo.',
        ),
      );
    }
  }

  Future<bool> markRead(String id) async {
    final recipientId = _recipientId;
    final item = state.items.where((item) => item.id == id).firstOrNull;
    if (recipientId == null || item == null || item.isRead) return item != null;
    final old = state;
    final updated = item.copyWith(readAt: DateTime.now());
    state = old.copyWith(
      items: old.items.map((item) => item.id == id ? updated : item).toList(),
    );
    try {
      await _repository.markRead(recipientId: recipientId, id: id);
      return ref.mounted && _recipientId == recipientId;
    } catch (_) {
      if (ref.mounted && _recipientId == recipientId) state = old;
      return false;
    }
  }

  Future<bool> markAllRead() async {
    final recipientId = _recipientId;
    if (recipientId == null || state.unreadCount == 0 || state.loading) {
      return false;
    }
    final old = state;
    final readAt = DateTime.now();
    state = old.copyWith(
      items: old.items
          .map((item) => item.isRead ? item : item.copyWith(readAt: readAt))
          .toList(),
    );
    try {
      await _repository.markAllRead(recipientId: recipientId);
      return ref.mounted && _recipientId == recipientId;
    } catch (_) {
      if (ref.mounted && _recipientId == recipientId) state = old;
      return false;
    }
  }

  void _validate(NotificationPage page, String recipientId) {
    if (page.total < page.items.length ||
        page.items.length > 20 ||
        page.items.map((item) => item.id).toSet().length != page.items.length ||
        page.items.any(
          (item) =>
              item.recipientId != recipientId ||
              item.id.isEmpty ||
              item.title.isEmpty,
        ) ||
        (page.nextCursor != null &&
            (page.nextCursor!.isEmpty || page.items.isEmpty))) {
      throw const AppException('Không đọc được dữ liệu thông báo.');
    }
  }
}
