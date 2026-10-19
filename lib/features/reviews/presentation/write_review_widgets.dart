part of 'write_review_screen.dart';

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.busy,
    required this.onSubmit,
    this.edit = false,
  });
  final bool busy;
  final bool edit;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surfaceContainerLowest.withValues(alpha: .96),
    elevation: 8,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          AppSpacing.sm,
          AppSpacing.margin,
          AppSpacing.sm,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: AppButton(
            label: edit ? 'Lưu thay đổi' : 'Gửi đánh giá',
            icon: Icons.send,
            iconAlignment: IconAlignment.end,
            expanded: true,
            isLoading: busy,
            onPressed: busy ? null : onSubmit,
          ),
        ),
      ),
    ),
  );
}

class _RestaurantSummary extends StatelessWidget {
  const _RestaurantSummary({required this.place});
  final Place place;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadii.inputBorder,
            child: AppImage(
              url: place.imageUrls.firstOrNull,
              width: 60,
              height: 60,
              semanticLabel: place.name,
            ),
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
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                    Icon(
                      Icons.verified,
                      size: 18,
                      color: context.colors.primary,
                    ),
                  ],
                ),
                Text(
                  '${place.category} · ${place.address}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  place.isDemo ? 'Dữ liệu minh họa' : 'Quán đã xác minh',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xem trang quán',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => context.push(
              AppRoute.restaurant.location(
                parameters: {'restaurantId': place.id},
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating, required this.onChanged});
  final int rating;
  final ValueChanged<int>? onChanged;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'Bạn đánh giá quán thế nào?',
            style: context.textStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: 'Đánh giá $rating sao',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    tooltip: '$star sao',
                    onPressed: onChanged == null
                        ? null
                        : () => onChanged!(star),
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 28,
                    style: IconButton.styleFrom(
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: Icon(
                      star <= rating ? Icons.star : Icons.star_border,
                      color: star <= rating
                          ? context.semanticColors.rating
                          : context.colors.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            _WriteReviewScreenState._ratingLabels[rating]!,
            style: context.textStyles.titleMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chạm để chọn số sao hài lòng của bạn',
            style: context.textStyles.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _WritingCard extends StatelessWidget {
  const _WritingCard({
    required this.title,
    required this.content,
    required this.busy,
    required this.onTag,
  });
  final TextEditingController title, content;
  final bool busy;
  final ValueChanged<String> onTag;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tiêu đề đánh giá (không bắt buộc)',
            style: context.textStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppTextField(
            controller: title,
            enabled: !busy,
            hintText: 'Tóm tắt trải nghiệm của bạn',
            prefixIcon: Icons.title_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Chia sẻ trải nghiệm của bạn ',
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: context.colors.error),
                      ),
                    ],
                  ),
                  style: context.textStyles.labelMedium,
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: content,
                builder: (_, value, _) => Text(
                  '${value.text.length}/1000',
                  style: context.textStyles.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            key: const ValueKey('review-content'),
            controller: content,
            enabled: !busy,
            maxLines: 5,
            maxLength: 1000,
            validator: (value) => value == null || value.trim().length < 10
                ? 'Hãy chia sẻ ít nhất 10 ký tự.'
                : null,
            decoration: const InputDecoration(
              hintText: 'Món ăn có vị chuẩn không? Không gian và thái độ phục vụ thế nào?',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gợi ý từ khóa yêu thích:',
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in _WriteReviewScreenState._quickTags)
                ActionChip(
                  label: Text('+ $tag'),
                  onPressed: busy ? null : () => onTag(tag),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PhotosCard extends StatelessWidget {
  const _PhotosCard({
    required this.photos,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });
  final List<_ReviewPhoto> photos;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Thêm ảnh thực tế',
                  style: context.textStyles.titleMedium,
                ),
              ),
              Text(
                '${photos.length}/6 ảnh',
                style: context.textStyles.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Chia sẻ hình ảnh món ăn hoặc không gian quán để cộng đồng dễ hình dung',
            style: context.textStyles.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) => index == 0
                  ? _AddPhotoTile(
                      enabled: !busy && photos.length < 6,
                      onTap: onAdd,
                    )
                  : _PhotoTile(
                      photo: photos[index - 1],
                      onRemove: busy ? null : () => onRemove(index - 1),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ảnh chọn từ thiết bị chỉ là bản xem trước; upload backend sẽ nối ở task dữ liệu.',
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.outline,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: AppRadii.inputBorder,
    child: Container(
      width: 78,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadii.inputBorder,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: context.colors.primary),
          const SizedBox(height: 2),
          Text(
            'Thêm ảnh',
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onRemove});
  final _ReviewPhoto photo;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: AppRadii.inputBorder,
        child: photo.bytes != null
            ? Image.memory(
                photo.bytes!,
                width: 78,
                height: 78,
                fit: BoxFit.cover,
              )
            : AppImage(url: photo.url, width: 78, height: 78),
      ),
      Positioned(
        top: 2,
        right: 2,
        child: IconButton(
          onPressed: onRemove,
          tooltip: 'Xóa ảnh',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          style: IconButton.styleFrom(
            backgroundColor: context.colors.scrim.withValues(alpha: .7),
            foregroundColor: context.colors.onPrimary,
          ),
          icon: const Icon(Icons.close, size: 14),
        ),
      ),
    ],
  );
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({
    required this.date,
    required this.companion,
    required this.busy,
    required this.onDate,
    required this.onCompanion,
  });
  final DateTime? date;
  final String? companion;
  final bool busy;
  final VoidCallback onDate;
  final ValueChanged<String?> onCompanion;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Thông tin chuyến đi', style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          Text('Thời gian ghé quán', style: context.textStyles.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          ListTile(
            leading: Icon(
              Icons.calendar_today_outlined,
              color: context.colors.primary,
            ),
            title: Text(
              date == null
                  ? 'Chọn ngày'
                  : 'Ngày ${date!.day}/${date!.month}/${date!.year}',
            ),
            trailing: const Icon(Icons.expand_more),
            contentPadding: EdgeInsets.zero,
            onTap: busy ? null : onDate,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Bạn đi cùng ai? (không bắt buộc)',
            style: context.textStyles.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in _WriteReviewScreenState._companions)
                ChoiceChip(
                  label: Text(item),
                  selected: companion == item,
                  onSelected: busy ? null : (_) => onCompanion(item),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _GuidelinesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: context.colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Hãy chia sẻ trải nghiệm chân thực và tôn trọng mọi người. Bài viết hữu ích giúp cộng đồng ẩm thực tìm được quán ngon chuẩn vị!',
              style: context.textStyles.labelSmall,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    color: context.semanticColors.warningContainer,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.semanticColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}
