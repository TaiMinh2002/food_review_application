import 'package:flutter/material.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/review_feed_repository.dart';

class ReviewSummaryCard extends StatelessWidget {
  const ReviewSummaryCard({super.key, required this.summary});
  final ReviewSummary summary;
  @override
  Widget build(BuildContext context) {
    final average = summary.averageRating;
    final metric = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            average?.toStringAsFixed(1) ?? '—',
            style: context.textStyles.headlineLarge,
          ),
          if (average != null)
            AppRating(value: average, showStars: true, showValue: false),
          const SizedBox(height: 4),
          Text(
            '${AppFormatters.count(summary.totalCount)} đánh giá',
            style: context.textStyles.labelSmall,
            textAlign: TextAlign.center,
          ),
          if (summary.highRatingPercent case final percent?) ...[
            const SizedBox(height: 8),
            AppBadge(label: '$percent% từ 4 sao', tone: AppBadgeTone.accent),
          ],
        ],
      ),
    );
    final chart = summary.starCounts == null
        ? const Text('Chưa có dữ liệu phân bố theo sao.')
        : Column(
            children: [
              for (var star = 5; star >= 1; star--)
                Semantics(
                  label:
                      '$star sao: ${summary.starCounts![star] ?? 0} đánh giá',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text('$star ★', style: context.textStyles.labelSmall),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: summary.totalCount == 0
                                ? 0
                                : (summary.starCounts![star] ?? 0) /
                                      summary.totalCount,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(8),
                            color: star >= 4
                                ? context.colors.primary
                                : context.colors.outline,
                            backgroundColor:
                                context.colors.surfaceContainerHigh,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppFormatters.count(summary.starCounts![star] ?? 0),
                          style: context.textStyles.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
    return Card(
      key: const ValueKey('review-summary'),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.inputBorder),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Đánh giá tổng quan', style: context.textStyles.headlineSmall),
            const SizedBox(height: 4),
            Text(
              summary.isDemo
                  ? 'Tổng hợp nhận xét minh họa'
                  : 'Đánh giá từ cộng đồng',
              style: context.textStyles.bodySmall,
            ),
            const Divider(height: 24),
            LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth < 290 ||
                      MediaQuery.textScalerOf(context).scale(14) > 19
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [metric, const SizedBox(height: 12), chart],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 5, child: metric),
                        const SizedBox(width: 12),
                        Expanded(flex: 7, child: chart),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewFilterChips extends StatelessWidget {
  const ReviewFilterChips({
    super.key,
    required this.filters,
    required this.onChanged,
    this.summary,
    this.wrap = false,
  });
  final ReviewFilters filters;
  final ValueChanged<ReviewFilters> onChanged;
  final ReviewSummary? summary;
  final bool wrap;
  @override
  Widget build(BuildContext context) {
    String count(int? value) =>
        value == null ? '' : ' (${AppFormatters.count(value)})';
    final chips = <Widget>[
      AppChip(
        label: 'Tất cả${count(summary?.totalCount)}',
        selected: filters.rating == null && !filters.withPhotos,
        onSelected: (_) => onChanged(ReviewFilters(sort: filters.sort)),
      ),
      for (var star = 5; star >= 1; star--)
        AppChip(
          label:
              '$star sao${count(summary?.starCounts == null ? null : summary!.starCounts![star] ?? 0)}',
          icon: Icons.star,
          selected: filters.rating == star,
          onSelected: (selected) =>
              onChanged(filters.copyWith(rating: star, clearRating: !selected)),
        ),
      AppChip(
        label: 'Có ảnh${count(summary?.withPhotosCount)}',
        icon: Icons.photo_camera_outlined,
        selected: filters.withPhotos,
        onSelected: (value) => onChanged(filters.copyWith(withPhotos: value)),
      ),
      const Tooltip(
        message: 'Chưa có dữ liệu xác thực trải nghiệm',
        child: AppChip(
          label: 'Đã xác thực',
          icon: Icons.verified_user_outlined,
        ),
      ),
    ];
    return wrap
        ? Wrap(spacing: 8, runSpacing: 4, children: chips)
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final chip in chips)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: chip,
                  ),
              ],
            ),
          );
  }
}

Future<ReviewFilters?> showReviewFilterSheet(
  BuildContext context,
  ReviewFilters initial,
  ReviewSummary? summary,
) {
  var draft = initial;
  return showAppBottomSheet<ReviewFilters>(
    context,
    title: 'Lọc và sắp xếp đánh giá',
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReviewFilterChips(
            filters: draft,
            summary: summary,
            wrap: true,
            onChanged: (value) => setState(() => draft = value),
          ),
          const SizedBox(height: 16),
          Text('Sắp xếp theo', style: context.textStyles.titleMedium),
          for (final sort in ReviewSort.values)
            ListTile(
              title: Text(sort.label),
              selected: draft.sort == sort,
              trailing: Icon(
                draft.sort == sort ? Icons.check_circle : Icons.circle_outlined,
              ),
              onTap: () => setState(() => draft = draft.copyWith(sort: sort)),
            ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Áp dụng',
            onPressed: () => Navigator.pop(context, draft),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => draft = const ReviewFilters()),
                child: const Text('Đặt lại'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class ReviewWriteBar extends StatelessWidget {
  const ReviewWriteBar({super.key, required this.onWrite});
  final VoidCallback onWrite;
  @override
  Widget build(BuildContext context) => Material(
    color: context.semanticColors.canvas,
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final prompt = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trải nghiệm của bạn?',
                      style: context.textStyles.labelMedium,
                    ),
                    Text(
                      'Chia sẻ ảnh & vị giác',
                      style: context.textStyles.labelSmall,
                    ),
                  ],
                );
                final action = AppButton(
                  label: 'Viết đánh giá',
                  icon: Icons.edit_note,
                  onPressed: onWrite,
                );
                return constraints.maxWidth < 320 ||
                        MediaQuery.textScalerOf(context).scale(14) > 19
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [prompt, const SizedBox(height: 8), action],
                      )
                    : Row(
                        children: [
                          Expanded(child: prompt),
                          const SizedBox(width: 12),
                          action,
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
