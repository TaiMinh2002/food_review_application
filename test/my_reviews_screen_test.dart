import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/reviews/data/demo_review_repository.dart';
import 'package:food_review/features/reviews/domain/review.dart';
import 'package:food_review/shared/widgets/app_button.dart';

import 'support/auth_harness.dart';

void main() {
  setUpAll(loadAuthFonts);

  Review review() => Review(
    id: 'review-user-a',
    placeId: 'pho-demo',
    userId: authTestUser.id,
    authorName: authTestUser.displayName,
    title: 'Bữa sáng đáng nhớ',
    rating: 4,
    content: 'Nước dùng thanh, thịt bò mềm và phục vụ nhanh.',
    createdAt: DateTime.utc(2026, 10, 12),
  );

  testWidgets('My reviews can edit an owned review and preserve its scope', (
    tester,
  ) async {
    final repo = DemoReviewRepository(data: [review()]);
    final container = await mountAuth(
      tester,
      ControlledAuth(user: authTestUser),
      route: '/my-reviews',
      reviews: repo,
    );
    await tester.pumpAndSettle();
    expect(find.text('Đánh giá của tôi'), findsOneWidget);
    await tester.tap(find.byTooltip('Tùy chọn đánh giá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa đánh giá'));
    await tester.pumpAndSettle();
    expect(find.text('Sửa đánh giá'), findsOneWidget);
    final editor = find.byKey(const ValueKey('review-content'));
    expect(find.text(review().content), findsOneWidget);
    await tester.enterText(
      editor,
      'Nước dùng thanh và thịt bò mềm hơn hôm trước.',
    );
    await tester.tap(find.widgetWithText(AppButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(container.read(appRouterProvider).state.uri.path, '/my-reviews');
    expect(
      (await repo.getReview('pho-demo', 'review-user-a'))?.content,
      'Nước dùng thanh và thịt bò mềm hơn hôm trước.',
    );
    expect(
      find.text('Nước dùng thanh và thịt bò mềm hơn hôm trước.'),
      findsOneWidget,
    );
    expect(find.text('Đã chỉnh sửa (1)'), findsOneWidget);
  });

  testWidgets('My reviews confirm deletion and remove only the owned review', (
    tester,
  ) async {
    final repo = DemoReviewRepository(data: [review()]);
    await mountAuth(
      tester,
      ControlledAuth(user: authTestUser),
      route: '/my-reviews',
      reviews: repo,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tùy chọn đánh giá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa đánh giá'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa đánh giá?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa đánh giá'));
    await tester.pumpAndSettle();
    expect(await repo.getReview('pho-demo', 'review-user-a'), isNull);
    expect(find.text('Bạn chưa có đánh giá nào'), findsOneWidget);
  });

  testWidgets('A different account cannot open the edit form', (tester) async {
    final repo = DemoReviewRepository(data: [review()]);
    await mountAuth(
      tester,
      ControlledAuth(
        user: const UserProfile(id: 'user-b', displayName: 'Người B'),
      ),
      route: '/reviews/review-user-a/edit?restaurantId=pho-demo',
      reviews: repo,
    );
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy đánh giá.'), findsOneWidget);
    expect(find.text(review().content), findsNothing);
  });
}
