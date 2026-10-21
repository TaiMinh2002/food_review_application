import 'package:flutter/material.dart';

import '../../../shared/design_system/design_system.dart';
import '../domain/report_repository.dart';

class ReportContextCard extends StatelessWidget {
  const ReportContextCard({super.key, required this.value});
  final ReportContext value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadii.inputBorder,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBadge(
          label: switch (value.target.type) {
            ReportTargetType.place => 'Quán ăn',
            ReportTargetType.review => 'Bài đánh giá',
            ReportTargetType.user => 'Người dùng',
          },
          icon: switch (value.target.type) {
            ReportTargetType.place => Icons.restaurant_outlined,
            ReportTargetType.review => Icons.rate_review_outlined,
            ReportTargetType.user => Icons.person_outline,
          },
        ),
        if (value.authorName != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppAvatar(name: value.authorName!, size: AppAvatarSize.small),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value.authorName!,
                  style: context.textStyles.titleMedium,
                ),
              ),
            ],
          ),
        ],
        if (value.excerpt != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Text(
              '“${value.excerpt}”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.small),
              child: AppImage(
                url: value.imageUrl,
                width: 48,
                height: 48,
                fallback: value.target.type == ReportTargetType.user
                    ? const Center(child: Icon(Icons.person_outline))
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value.title, style: context.textStyles.titleMedium),
                  if (value.subtitle != null)
                    Text(
                      value.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Hãy cho chúng tôi biết vấn đề bạn gặp phải.',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class ReportNotice extends StatelessWidget {
  const ReportNotice({super.key, required this.isDemo});
  final bool isDemo;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLow,
      borderRadius: AppRadii.inputBorder,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_user_outlined,
          size: 20,
          color: context.colors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            isDemo
                ? 'Chế độ minh họa: báo cáo và ảnh chỉ lưu trong phiên ứng dụng, chưa gửi đến đội ngũ kiểm duyệt. Vui lòng cung cấp thông tin trung thực.'
                : 'Báo cáo của bạn sẽ được gửi đến đội ngũ kiểm duyệt. Vui lòng cung cấp thông tin trung thực.',
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class ReportEvidencePicker extends StatelessWidget {
  const ReportEvidencePicker({
    super.key,
    required this.photos,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });
  final List<ReportEvidence> photos;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Ảnh minh chứng (không bắt buộc)',
        style: context.textStyles.titleMedium,
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: OutlinedButton(
              onPressed: busy || photos.length >= 3 ? null : onAdd,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.xs),
                backgroundColor: context.colors.surfaceContainerLow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Thêm ảnh', style: context.textStyles.bodySmall),
                ],
              ),
            ),
          ),
          for (var index = 0; index < photos.length; index++)
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: AppRadii.inputBorder,
                      child: Image.memory(
                        photos[index].bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: context.colors.surfaceContainerLow,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      tooltip: 'Xóa ảnh minh chứng ${index + 1}',
                      onPressed: busy ? null : () => onRemove(index),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.surface.withValues(
                          alpha: .9,
                        ),
                      ),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Tối đa 3 ảnh JPG, PNG • Mỗi ảnh không quá 5 MB',
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
