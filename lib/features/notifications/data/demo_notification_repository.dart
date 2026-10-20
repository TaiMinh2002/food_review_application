import '../../../core/errors/app_exception.dart';
import '../domain/notification_repository.dart';

/// Illustrative inbox data held in memory for the active app process.
class DemoNotificationRepository implements NotificationRepository {
  final _records = <String, List<AppNotification>>{};

  @override
  bool get isDemo => true;

  List<AppNotification> _forRecipient(String recipientId) {
    if (recipientId.trim().isEmpty) {
      throw const AppException('Vui lòng đăng nhập để xem thông báo.');
    }
    return _records.putIfAbsent(recipientId, () {
      final now = DateTime.now();
      return [
        AppNotification(
          id: 'helpful',
          recipientId: recipientId,
          kind: AppNotificationKind.helpful,
          title: 'Đánh giá nhận được lượt hữu ích',
          message: 'Có thêm 5 người thấy đánh giá của bạn về Phở Thìn Bờ Hồ hữu ích và tâm huyết.',
          createdAt: now.subtract(const Duration(minutes: 10)),
          targetType: NotificationTargetType.myReviews,
          imageUrl: 'assets/images/demo/pho.jpg',
        ),
        AppNotification(
          id: 'approved',
          recipientId: recipientId,
          kind: AppNotificationKind.approved,
          title: 'Đánh giá đã được phê duyệt',
          message: 'Bài viết chia sẻ về Bánh Mì 25 đã được duyệt và hiển thị công khai.',
          createdAt: now.subtract(const Duration(hours: 2)),
          targetType: NotificationTargetType.restaurant,
          targetId: 'banh-mi-demo',
          imageUrl: 'assets/images/demo/banh_mi.jpg',
        ),
        AppNotification(
          id: 'discover',
          recipientId: recipientId,
          kind: AppNotificationKind.discovery,
          title: 'Khám phá địa điểm mới tuần này',
          message: 'Nhiều quán cà phê sân vườn và quán ăn gia truyền vừa cập bến phố cổ Hà Nội. Thử ngay!',
          createdAt: now.subtract(const Duration(hours: 5)),
          targetType: NotificationTargetType.home,
        ),
        AppNotification(
          id: 'saved',
          recipientId: recipientId,
          kind: AppNotificationKind.reminder,
          title: 'Đừng quên quán bạn đã lưu',
          message: 'Bạn có các quán ăn trong bộ sưu tập “Cuối tuần tụ tập” gần vị trí hiện tại.',
          createdAt: now.subtract(const Duration(days: 1, hours: 6)),
          readAt: now.subtract(const Duration(days: 1, hours: 5)),
          targetType: NotificationTargetType.collections,
        ),
        AppNotification(
          id: 'welcome',
          recipientId: recipientId,
          kind: AppNotificationKind.welcome,
          title: 'Chào mừng đến với Food Review',
          message: 'Cảm ơn bạn đã tham gia cộng đồng khám phá và sẻ chia đam mê ẩm thực Việt Nam.',
          createdAt: now.subtract(const Duration(days: 3)),
          readAt: now.subtract(const Duration(days: 3)),
        ),
      ];
    });
  }

  @override
  Future<NotificationPage> getNotifications({
    required String recipientId,
    String? cursor,
    int limit = 20,
  }) async {
    if (limit < 1 || limit > 50) throw ArgumentError.value(limit, 'limit');
    final offset = cursor == null ? 0 : int.tryParse(cursor);
    if (offset == null || offset < 0) {
      throw const AppException(
        'Không tải được trang thông báo. Vui lòng thử lại.',
      );
    }
    final records = _forRecipient(recipientId)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (offset > records.length) {
      throw const AppException(
        'Danh sách thông báo đã thay đổi. Vui lòng tải lại.',
      );
    }
    final end = (offset + limit).clamp(0, records.length);
    return NotificationPage(
      items: List.unmodifiable(records.sublist(offset, end)),
      total: records.length,
      nextCursor: end < records.length ? '$end' : null,
      isDemo: true,
    );
  }

  @override
  Future<void> markRead({
    required String recipientId,
    required String id,
  }) async {
    final records = _forRecipient(recipientId);
    final index = records.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw const AppException('Thông báo không còn tồn tại.');
    }
    if (!records[index].isRead) {
      records[index] = records[index].copyWith(readAt: DateTime.now());
    }
  }

  @override
  Future<void> markAllRead({required String recipientId}) async {
    final records = _forRecipient(recipientId);
    final now = DateTime.now();
    for (var index = 0; index < records.length; index++) {
      if (!records[index].isRead) {
        records[index] = records[index].copyWith(readAt: now);
      }
    }
  }
}
