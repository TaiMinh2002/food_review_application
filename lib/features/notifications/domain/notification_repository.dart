/// A notification stays owned by the recipient and only contains a typed,
/// internal destination. It never carries a URL supplied by a remote sender.
enum NotificationTargetType { restaurant, collections, myReviews, home, none }

enum AppNotificationKind { helpful, approved, discovery, reminder, welcome }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
    this.targetType = NotificationTargetType.none,
    this.targetId,
    this.imageUrl,
  });

  final String id, recipientId, title, message;
  final AppNotificationKind kind;
  final DateTime createdAt;
  final DateTime? readAt;
  final NotificationTargetType targetType;
  final String? targetId, imageUrl;
  bool get isRead => readAt != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
    id: id,
    recipientId: recipientId,
    kind: kind,
    title: title,
    message: message,
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
    targetType: targetType,
    targetId: targetId,
    imageUrl: imageUrl,
  );
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.total,
    this.nextCursor,
    this.isDemo = false,
  });
  final List<AppNotification> items;
  final int total;
  final String? nextCursor;
  final bool isDemo;
}

abstract interface class NotificationRepository {
  bool get isDemo;
  Future<NotificationPage> getNotifications({
    required String recipientId,
    String? cursor,
    int limit = 20,
  });
  Future<void> markRead({required String recipientId, required String id});
  Future<void> markAllRead({required String recipientId});
}
