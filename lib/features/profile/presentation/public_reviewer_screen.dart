import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/public_reviewer_repository.dart';
import 'public_reviewer_controller.dart';
import 'public_reviewer_widgets.dart';

class PublicReviewerScreen extends ConsumerWidget {
  const PublicReviewerScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publicReviewerControllerProvider(userId));
    final controller = ref.read(
      publicReviewerControllerProvider(userId).notifier,
    );
    final profile = state.profile;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: const RouteBackButton(),
        title: Text(profile?.name ?? 'Hồ sơ người đánh giá', maxLines: 2),
        toolbarHeight: 64 * MediaQuery.textScalerOf(context).scale(14) / 14,
        actions: [if (profile != null) _ProfileOptions(profile: profile)],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 3,
        destinations: mainAppDestinations,
        onSelected: (index) => context.go(
          [
            AppRoute.home,
            AppRoute.map,
            AppRoute.favorites,
            AppRoute.profile,
          ][index].path,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: CustomScrollView(
                key: PageStorageKey('public-reviewer-$userId'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (state.loading && profile == null)
                    const SliverPadding(
                      padding: AppSpacing.page,
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            AppSkeleton(height: 300),
                            SizedBox(height: AppSpacing.xl),
                            AppSkeleton(height: 100),
                          ],
                        ),
                      ),
                    )
                  else if (state.error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppErrorState(
                        message: state.error!,
                        onRetry: controller.refresh,
                      ),
                    )
                  else if (profile == null)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        title: 'Hồ sơ không còn khả dụng',
                        message:
                            'Người dùng không tồn tại hoặc hồ sơ đã được ẩn.',
                        icon: Icons.person_off_outlined,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.margin,
                        AppSpacing.sm,
                        AppSpacing.margin,
                        AppSpacing.xxl,
                      ),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PublicReviewerHeader(
                                  profile: profile,
                                  options: _ProfileOptions(
                                    profile: profile,
                                    inline: true,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                PublicReviewerStats(profile: profile),
                                if (profile.featured != null) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Đánh giá nổi bật',
                                        style: context.textStyles.headlineSmall,
                                      ),
                                      const AppBadge(
                                        label: 'Nổi bật',
                                        icon: Icons.auto_awesome,
                                        tone: AppBadgeTone.accent,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  PublicReviewerReviewCard(
                                    review: profile.featured!,
                                    featured: true,
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.xl),
                                Text(
                                  'Bài đánh giá (${profile.reviewCount})',
                                  style: context.textStyles.headlineSmall,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    for (final filter
                                        in PublicReviewFilter.values)
                                      AppChip(
                                        label: switch (filter) {
                                          PublicReviewFilter.newest =>
                                            'Mới nhất',
                                          PublicReviewFilter.ratingHigh =>
                                            'Điểm cao',
                                          PublicReviewFilter.withPhotos =>
                                            'Có ảnh',
                                        },
                                        selected: state.filter == filter,
                                        onSelected: (_) =>
                                            controller.apply(filter),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                            ),
                          ),
                          if (state.items.isEmpty)
                            SliverToBoxAdapter(
                              child: AppEmptyState(
                                title:
                                    state.filter ==
                                        PublicReviewFilter.withPhotos
                                    ? 'Chưa có đánh giá có ảnh'
                                    : 'Chưa có bài đánh giá',
                                message: 'Các đánh giá công khai của người dùng này sẽ xuất hiện tại đây.',
                                icon: Icons.rate_review_outlined,
                              ),
                            )
                          else
                            SliverList.separated(
                              itemCount: state.items.length,
                              itemBuilder: (_, index) =>
                                  PublicReviewerReviewCard(
                                    review: state.items[index],
                                  ),
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.md),
                            ),
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                if (state.pageError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.md,
                                    ),
                                    child: Text(
                                      state.pageError!,
                                      style: context.textStyles.bodyMedium
                                          ?.copyWith(
                                            color: context.colors.error,
                                          ),
                                    ),
                                  ),
                                if (state.nextCursor != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.lg,
                                    ),
                                    child: AppButton(
                                      label: state.pageError == null
                                          ? 'Xem thêm đánh giá'
                                          : 'Thử tải lại',
                                      isLoading: state.loadingMore,
                                      onPressed: controller.loadMore,
                                      variant: AppButtonVariant.outline,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ProfileAction { copy, report }

class _ProfileOptions extends StatelessWidget {
  const _ProfileOptions({required this.profile, this.inline = false});
  final PublicReviewer profile;
  final bool inline;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_ProfileAction>(
    tooltip: inline ? 'Tùy chọn hồ sơ' : 'Tùy chọn khác',
    icon: inline ? null : const Icon(Icons.more_vert),
    onSelected: (action) async {
      if (action == _ProfileAction.report) {
        context.push(
          AppRoute.createReport.location(
            query: {'targetType': 'user', 'userId': profile.id},
          ),
        );
      } else {
        try {
          await Clipboard.setData(
            ClipboardData(
              text: AppRoute.reviewer.location(
                parameters: {'userId': profile.id},
              ),
            ),
          );
          if (context.mounted) {
            AppToast.show(
              context,
              'Đã sao chép đường dẫn hồ sơ trong ứng dụng.',
            );
          }
        } catch (_) {
          if (context.mounted) {
            AppToast.show(
              context,
              'Không sao chép được đường dẫn. Vui lòng thử lại.',
              type: AppFeedbackType.error,
            );
          }
        }
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: _ProfileAction.copy,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.link),
          title: Text('Sao chép đường dẫn hồ sơ'),
        ),
      ),
      PopupMenuItem(
        value: _ProfileAction.report,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.flag_outlined),
          title: Text('Báo cáo người dùng'),
        ),
      ),
    ],
    child: inline
        ? Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, size: 18),
                SizedBox(width: AppSpacing.xs),
                Text('Tùy chọn'),
              ],
            ),
          )
        : null,
  );
}
