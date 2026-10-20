import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../places/presentation/place_providers.dart';
import '../domain/notification_repository.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: const Text('Thông báo'),
      centerTitle: false,
      leading: const RouteBackButton(),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(notificationsControllerProvider);
            return IconButton(
              tooltip: 'Đánh dấu đã đọc',
              onPressed: state.unreadCount == 0 || state.loading
                  ? null
                  : () => _markAllRead(context, ref),
              icon: const Icon(Icons.done_all),
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    ),
    body: SafeArea(
      top: false,
      child: AuthGate(
        returnTo: AppRoute.notifications.path,
        child: const _NotificationsBody(),
      ),
    ),
  );

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(notificationsControllerProvider.notifier)
        .markAllRead();
    if (!context.mounted || !success) {
      if (context.mounted) {
        AppToast.show(
          context,
          'Không thể cập nhật thông báo. Vui lòng thử lại.',
          type: AppFeedbackType.error,
        );
      }
      return;
    }
    AppToast.show(
      context,
      'Đã đánh dấu các thông báo là đã đọc',
      type: AppFeedbackType.success,
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  const _NotificationsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final groups = _groupItems(state.items, DateTime.now());
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        key: const PageStorageKey('notifications-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.margin,
              AppSpacing.md,
              AppSpacing.margin,
              AppSpacing.xxl,
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                if (state.isDemo)
                  const SliverToBoxAdapter(child: _DemoNotice()),
                if (state.refreshing)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: LinearProgressIndicator(
                        semanticsLabel: 'Đang cập nhật thông báo',
                      ),
                    ),
                  ),
                if (state.error != null && state.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppErrorState(
                      message: state.error!,
                      onRetry: controller.refresh,
                    ),
                  )
                else if (state.loading && state.items.isEmpty)
                  const SliverToBoxAdapter(child: _NotificationSkeleton())
                else if (state.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'Bạn chưa có thông báo nào',
                      message: 'Khi có hoạt động mới, thông báo sẽ xuất hiện tại đây.',
                      actionLabel: 'Về trang cá nhân',
                      onAction: () => context.go(AppRoute.profile.path),
                    ),
                  )
                else ...[
                  if (state.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppErrorState(
                          message: state.error!,
                          onRetry: controller.refresh,
                        ),
                      ),
                    ),
                  for (final group in groups)
                    _NotificationGroupSliver(
                      group: group,
                      onTap: (item) => _open(context, ref, item),
                    ),
                  SliverToBoxAdapter(
                    child: _PagingFooter(
                      state: state,
                      onLoadMore: controller.loadMore,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    AppNotification item,
  ) async {
    final sessionId = ref.read(authSessionProvider).asData?.value?.id;
    final marked = await ref
        .read(notificationsControllerProvider.notifier)
        .markRead(item.id);
    if (!context.mounted ||
        !marked ||
        ref.read(authSessionProvider).asData?.value?.id != sessionId) {
      return;
    }
    switch (item.targetType) {
      case NotificationTargetType.restaurant:
        final id = item.targetId;
        if (id == null || id.isEmpty) {
          return _unavailable(context);
        }
        final place = await ref.read(placeRepositoryProvider).getPlace(id);
        if (!context.mounted ||
            ref.read(authSessionProvider).asData?.value?.id != sessionId) {
          return;
        }
        if (place == null) {
          return _unavailable(context);
        }
        context.push(
          AppRoute.restaurant.location(parameters: {'restaurantId': id}),
        );
      case NotificationTargetType.collections:
        context.push(AppRoute.collections.path);
      case NotificationTargetType.myReviews:
        context.push(AppRoute.myReviews.path);
      case NotificationTargetType.home:
        context.go(AppRoute.home.path);
      case NotificationTargetType.none:
        AppToast.show(context, 'Thông báo này không có nội dung để mở.');
    }
  }

  void _unavailable(BuildContext context) => AppToast.show(
    context,
    'Nội dung liên quan không còn khả dụng.',
    type: AppFeedbackType.warning,
  );
}

class _NotificationGroup {
  const _NotificationGroup(this.title, this.items, {this.latest = false});
  final String title;
  final List<AppNotification> items;
  final bool latest;
}

List<_NotificationGroup> _groupItems(
  List<AppNotification> items,
  DateTime now,
) {
  final today = <AppNotification>[];
  final yesterday = <AppNotification>[];
  final older = <AppNotification>[];
  final startToday = DateTime(now.year, now.month, now.day);
  final startYesterday = startToday.subtract(const Duration(days: 1));
  for (final item in items) {
    if (!item.createdAt.isBefore(startToday)) {
      today.add(item);
    } else if (!item.createdAt.isBefore(startYesterday)) {
      yesterday.add(item);
    } else {
      older.add(item);
    }
  }
  return [
    if (today.isNotEmpty) _NotificationGroup('Hôm nay', today, latest: true),
    if (yesterday.isNotEmpty) _NotificationGroup('Hôm qua', yesterday),
    if (older.isNotEmpty) _NotificationGroup('Trước đó', older),
  ];
}

class _NotificationGroupSliver extends StatelessWidget {
  const _NotificationGroupSliver({required this.group, required this.onTap});
  final _NotificationGroup group;
  final ValueChanged<AppNotification> onTap;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group.title,
                  style: context.textStyles.headlineSmall,
                ),
              ),
              if (group.latest)
                Text(
                  'MỚI NHẤT',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
      SliverList.separated(
        itemCount: group.items.length,
        itemBuilder: (context, index) => NotificationTile(
          item: group.items[index],
          onTap: () => onTap(group.items[index]),
        ),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      ),
    ],
  );
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item, required this.onTap});
  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = switch (item.kind) {
      AppNotificationKind.helpful => Icons.thumb_up_alt_rounded,
      AppNotificationKind.approved => Icons.verified_rounded,
      AppNotificationKind.discovery => Icons.restaurant_menu_rounded,
      AppNotificationKind.reminder => Icons.favorite_rounded,
      AppNotificationKind.welcome => Icons.celebration_rounded,
    };
    final background = switch (item.kind) {
      AppNotificationKind.helpful ||
      AppNotificationKind.welcome => colors.primaryContainer,
      AppNotificationKind.approved => colors.secondaryContainer,
      AppNotificationKind.discovery => context.semanticColors.warningContainer,
      AppNotificationKind.reminder => colors.errorContainer,
    };
    final foreground = switch (item.kind) {
      AppNotificationKind.helpful ||
      AppNotificationKind.welcome => colors.onPrimaryContainer,
      AppNotificationKind.approved => colors.onSecondaryContainer,
      AppNotificationKind.discovery => context.semanticColors.warning,
      AppNotificationKind.reminder => colors.error,
    };
    return Material(
      color: item.isRead ? colors.surface : colors.surfaceContainerLow,
      borderRadius: AppRadii.inputBorder,
      child: InkWell(
        key: ValueKey('notification-${item.id}'),
        borderRadius: AppRadii.inputBorder,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: AppRadii.inputBorder,
                ),
                child: Icon(icon, color: foreground, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.titleMedium?.copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Padding(
                            padding: const EdgeInsets.only(left: AppSpacing.sm),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox(width: 8, height: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: item.isRead
                            ? colors.outline
                            : colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          item.isRead ? Icons.history : Icons.schedule,
                          size: 14,
                          color: colors.outline,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _timeLabel(item.createdAt, DateTime.now()),
                          style: context.textStyles.labelSmall?.copyWith(
                            color: colors.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (item.imageUrl != null) ...[
                const SizedBox(width: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.small),
                  child: AppImage(url: item.imageUrl, width: 44, height: 44),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _timeLabel(DateTime value, DateTime now) {
  final difference = now.difference(value);
  if (difference.inMinutes < 1) {
    return 'Vừa xong';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} phút trước';
  }
  if (difference.inHours < 24 && DateUtils.isSameDay(value, now)) {
    return '${difference.inHours} giờ trước';
  }
  if (DateUtils.isSameDay(value, now.subtract(const Duration(days: 1)))) {
    return 'Hôm qua, ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} ngày trước';
  }
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLow,
      borderRadius: AppRadii.inputBorder,
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 18, color: context.colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Thông báo mẫu chỉ được lưu trong phiên ứng dụng.',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < 4; index++) ...[
        if (index == 0)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppSkeleton(height: 26, width: 96),
          ),
        const AppSkeleton(height: 112),
        const SizedBox(height: AppSpacing.sm),
      ],
    ],
  );
}

class _PagingFooter extends StatelessWidget {
  const _PagingFooter({required this.state, required this.onLoadMore});
  final NotificationsState state;
  final Future<void> Function() onLoadMore;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    child: Column(
      children: [
        if (state.pageError != null)
          Text(
            state.pageError!,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.error,
            ),
          ),
        if (state.pageError != null)
          TextButton(onPressed: onLoadMore, child: const Text('Thử tải lại')),
        if (state.loadingMore)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: CircularProgressIndicator(),
          ),
        if (state.nextCursor != null && !state.loadingMore)
          OutlinedButton(
            onPressed: onLoadMore,
            child: const Text('Xem thêm thông báo'),
          ),
      ],
    ),
  );
}
