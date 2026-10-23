import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../../places/domain/place.dart';
import '../../places/presentation/place_providers.dart';
import '../domain/review.dart';
import 'review_write_controller.dart';
import 'review_providers.dart';
part 'write_review_widgets.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({
    super.key,
    required this.placeId,
    this.reviewId,
    this.scope = 'write-review',
  });

  final String placeId;
  final String? reviewId;
  final String scope;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _ReviewPhoto {
  const _ReviewPhoto({this.url, this.bytes, this.label});
  final String? url;
  final Uint8List? bytes;
  final String? label;
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _picker = ImagePicker();
  final _photos = <_ReviewPhoto>[];
  int _rating = 4;
  String? _companion = 'Bạn bè';
  DateTime? _visitDate = DateTime.now();
  bool _seededReview = false;

  static const _ratingLabels = <int, String>{
    1: 'Chưa hài lòng',
    2: 'Bình thường',
    3: 'Khá ổn',
    4: 'Rất tốt',
    5: 'Xuất sắc tuyệt vời',
  };
  static const _quickTags = [
    'Nước dùng thanh ngọt',
    'Thịt bò tái mềm',
    'Phục vụ nhanh',
    'Chuẩn vị phố cổ',
  ];
  static const _companions = [
    'Một mình',
    'Bạn bè',
    'Gia đình',
    'Người yêu',
    'Đồng nghiệp',
  ];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _seedReview(Review review) {
    if (_seededReview) return;
    _seededReview = true;
    _rating = review.rating;
    _title.text = review.title ?? '';
    _body.text = review.content;
    _visitDate = review.visitDate;
    _companion = review.companion;
    _photos.addAll(
      review.imageUrls.map(
        (url) => _ReviewPhoto(url: url, label: 'Ảnh đánh giá'),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 6) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _photos.add(_ReviewPhoto(bytes: bytes, label: picked.name)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _visitDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: 'Chọn ngày ghé quán',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (date != null && mounted) setState(() => _visitDate = date);
  }

  void _appendTag(String tag) {
    final current = _body.text.trim();
    final next = current.isEmpty ? tag : '$current, ${tag.toLowerCase()}';
    _body.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final controller = ref.read(
      reviewWriteControllerProvider(widget.scope).notifier,
    );
    final existingUrls = _photos
        .where((photo) => photo.url != null && photo.bytes == null)
        .map((photo) => photo.url!)
        .toList();
    final newPhotos = _photos
        .where((photo) => photo.bytes != null)
        .map(
          (photo) => (
            bytes: photo.bytes!,
            filename: photo.label ?? 'review_photo.jpg',
          ),
        )
        .toList();

    if (widget.reviewId case final reviewId?) {
      final existing = ref
          .read(
            reviewForEditProvider((
              placeId: widget.placeId,
              reviewId: reviewId,
            )),
          )
          .asData
          ?.value;
      if (existing == null) return;
      await controller.updateReview(
        placeId: widget.placeId,
        reviewId: reviewId,
        rating: _rating,
        title: _title.text,
        content: _body.text,
        visitDate: _visitDate,
        companion: _companion,
        createdAt: existing.createdAt,
        imageUrls: existingUrls,
        newPhotos: newPhotos,
      );
    } else {
      await controller.submit(
        placeId: widget.placeId,
        rating: _rating,
        title: _title.text,
        content: _body.text,
        visitDate: _visitDate,
        companion: _companion,
        imageUrls: existingUrls,
        newPhotos: newPhotos,
      );
    }
    if (!mounted) return;
    if (!ref.read(reviewWriteControllerProvider(widget.scope)).hasError) {
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(
          AppRoute.restaurant.location(
            parameters: {'restaurantId': widget.placeId},
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeState = ref.watch(placeProvider(widget.placeId));
    final operation = ref.watch(reviewWriteControllerProvider(widget.scope));
    final reviewState = widget.reviewId == null
        ? const AsyncData<Review?>(null)
        : ref.watch(
            reviewForEditProvider((
              placeId: widget.placeId,
              reviewId: widget.reviewId!,
            )),
          );
    final busy = operation.isLoading;
    return Scaffold(
      appBar: AppBar(
        leading: const RouteBackButton(),
        title: Text(widget.reviewId == null ? 'Viết đánh giá' : 'Sửa đánh giá'),
        actions: [
          IconButton(
            tooltip: 'Xem trang quán',
            onPressed: () => context.push(
              AppRoute.restaurant.location(
                parameters: {'restaurantId': widget.placeId},
              ),
            ),
            icon: const Icon(Icons.person_pin_circle_outlined),
          ),
        ],
      ),
      bottomNavigationBar: _SubmitBar(
        busy: busy,
        onSubmit: _submit,
        edit: widget.reviewId != null,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: reviewState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Đang tải đánh giá',
            ),
          ),
          error: (error, _) => AppErrorState(
            message: AppErrorMessage.from(
              error,
              fallback: 'Không tải được đánh giá.',
            ),
            onRetry: () => ref.invalidate(
              reviewForEditProvider((
                placeId: widget.placeId,
                reviewId: widget.reviewId!,
              )),
            ),
          ),
          data: (review) {
            if (review == null && widget.reviewId != null) {
              return const AppEmptyState(
                title: 'Không tìm thấy đánh giá.',
                message:
                    'Đánh giá có thể đã bị xóa hoặc không thuộc tài khoản này.',
                icon: Icons.rate_review_outlined,
              );
            }
            if (review != null) _seedReview(review);
            return placeState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Đang tải thông tin quán',
                ),
              ),
              error: (error, _) => AppErrorState(
                message: AppErrorMessage.from(
                  error,
                  fallback: 'Không tải được thông tin quán.',
                ),
                onRetry: () => ref.invalidate(placeProvider(widget.placeId)),
              ),
              data: (place) => place == null
                  ? const AppEmptyState(
                      title: 'Không tìm thấy quán.',
                      message: 'Vui lòng quay lại và chọn một quán khác.',
                      icon: Icons.storefront_outlined,
                    )
                  : _content(place, busy, operation),
            );
          },
        ),
      ),
    );
  }

  Widget _content(Place place, bool busy, AsyncValue<void> operation) {
    return CustomScrollView(
      key: PageStorageKey('write-review-${place.id}'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margin,
            AppSpacing.md,
            AppSpacing.margin,
            150,
          ),
          sliver: SliverToBoxAdapter(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RestaurantSummary(place: place),
                  const SizedBox(height: AppSpacing.lg),
                  _RatingCard(
                    rating: _rating,
                    onChanged: busy
                        ? null
                        : (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _WritingCard(
                    title: _title,
                    content: _body,
                    busy: busy,
                    onTag: _appendTag,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PhotosCard(
                    photos: _photos,
                    busy: busy,
                    onAdd: _pickPhoto,
                    onRemove: (index) =>
                        setState(() => _photos.removeAt(index)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _VisitCard(
                    date: _visitDate,
                    companion: _companion,
                    busy: busy,
                    onDate: _pickDate,
                    onCompanion: (value) => setState(() => _companion = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GuidelinesCard(),
                  if (operation.hasError) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ReviewError(
                      message: AppErrorMessage.from(
                        operation.error!,
                        fallback: 'Không đăng được đánh giá. Vui lòng thử lại.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
