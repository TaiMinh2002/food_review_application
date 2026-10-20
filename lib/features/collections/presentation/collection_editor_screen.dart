import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/collection_editor.dart';
import 'collection_editor_controller.dart';
import 'collection_editor_widgets.dart';
import 'collection_place_picker.dart';
import 'collections_controller.dart';

class CollectionEditorScreen extends ConsumerWidget {
  const CollectionEditorScreen({
    super.key,
    this.collectionId,
    required this.scope,
  });
  final String? collectionId;
  final String scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final user = session.isLoading || session.hasError
        ? null
        : session.asData?.value;
    final returnTo = collectionId == null
        ? AppRoute.createCollection.path
        : AppRoute.editCollection.location(
            parameters: {'collectionId': collectionId!},
          );
    return AuthGate(
      returnTo: returnTo,
      child: user == null
          ? const SizedBox.shrink()
          : _CollectionLoader(
              key: ValueKey((user.id, collectionId, scope)),
              editorKey: (
                ownerId: user.id,
                collectionId: collectionId,
                scope: scope,
              ),
            ),
    );
  }
}

class _CollectionLoader extends ConsumerWidget {
  const _CollectionLoader({super.key, required this.editorKey});
  final CollectionEditorKey editorKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(collectionDetailProvider(editorKey));
    final repository = ref.watch(collectionRepositoryProvider);
    final isDemo =
        repository is CollectionEditingRepository &&
        (repository as CollectionEditingRepository).isDemo;
    return detail.when(
      skipLoadingOnReload: false,
      skipLoadingOnRefresh: false,
      data: (value) => editorKey.collectionId != null && value == null
          ? _EditorStatus(
              title: 'Không tìm thấy bộ sưu tập',
              message: 'Bộ sưu tập không tồn tại hoặc không thuộc tài khoản của bạn.',
            )
          : _CollectionForm(
              editorKey: editorKey,
              detail: value,
              isDemo: isDemo,
            ),
      loading: () => const _EditorStatus(loading: true),
      error: (error, _) => _EditorStatus(
        title: 'Không tải được bộ sưu tập',
        message: AppErrorMessage.from(error, fallback: 'Vui lòng thử lại.'),
        onRetry: () => ref.invalidate(collectionDetailProvider(editorKey)),
      ),
    );
  }
}

class _EditorStatus extends StatelessWidget {
  const _EditorStatus({
    this.title = '',
    this.message = '',
    this.loading = false,
    this.onRetry,
  });
  final String title, message;
  final bool loading;
  final VoidCallback? onRetry;
  void _leave(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoute.collections.path);
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: context.canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave(context);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Bộ sưu tập'),
        leading: BackButton(onPressed: () => _leave(context)),
      ),
      body: SafeArea(
        child: loading
            ? const Padding(
                padding: AppSpacing.page,
                child: AppSkeleton(height: 260),
              )
            : SingleChildScrollView(
                child: onRetry != null
                    ? AppErrorState(
                        message: '$title. $message',
                        onRetry: onRetry!,
                      )
                    : AppEmptyState(
                        title: title,
                        message: message,
                        actionLabel: 'Về bộ sưu tập',
                        onAction: () => _leave(context),
                      ),
              ),
      ),
    ),
  );
}

class _CollectionForm extends ConsumerStatefulWidget {
  const _CollectionForm({
    required this.editorKey,
    required this.detail,
    required this.isDemo,
  });
  final CollectionEditorKey editorKey;
  final CollectionDetail? detail;
  final bool isDemo;
  @override
  ConsumerState<_CollectionForm> createState() => _CollectionFormState();
}

class _CollectionFormState extends ConsumerState<_CollectionForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.detail?.name ?? '');
  late final _description = TextEditingController(
    text: widget.detail?.description ?? '',
  );
  late List<CollectionPlace> _places = List.of(widget.detail?.places ?? []);
  bool _leaving = false, _confirming = false, _picking = false;
  bool get _editing => widget.editorKey.collectionId != null;
  bool get _dirty =>
      _name.text.trim() != (widget.detail?.name ?? '').trim() ||
      _description.text.trim() != (widget.detail?.description ?? '').trim() ||
      !listEquals(
        _places.map((p) => p.id).toList(),
        (widget.detail?.places ?? []).map((p) => p.id).toList(),
      );

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _leave() {
    if (_leaving) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoute.collections.path);
      }
    });
  }

  Future<void> _cancel() async {
    if (_confirming ||
        _leaving ||
        ref.read(collectionSaveProvider(widget.editorKey)).isLoading) {
      return;
    }
    FocusScope.of(context).unfocus();
    if (_dirty) {
      _confirming = true;
      final discard = await showAppConfirmation(
        context,
        title: 'Bỏ thay đổi?',
        message: 'Những thay đổi bạn vừa thực hiện trên bộ sưu tập này sẽ không được lưu.',
        confirmLabel: 'Bỏ thay đổi',
        cancelLabel: 'Tiếp tục chỉnh sửa',
        destructive: true,
      );
      if (!mounted) return;
      _confirming = false;
      if (!discard) return;
    }
    _leave();
  }

  Future<void> _pick() async {
    if (_picking) return;
    FocusScope.of(context).unfocus();
    setState(() => _picking = true);
    final selected = await pickCollectionPlaces(
      context,
      ownerId: widget.editorKey.ownerId,
      selected: _places,
    );
    if (!mounted) return;
    setState(() {
      _picking = false;
      if (selected != null) _places = List.of(selected);
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final id = await ref
        .read(collectionSaveProvider(widget.editorKey).notifier)
        .save(
          CollectionDraft(
            name: _name.text,
            description: _description.text,
            placeIds: _places.map((p) => p.id),
          ),
        );
    if (!mounted || id == null) return;
    AppToast.show(
      context,
      _editing ? 'Đã lưu thay đổi' : 'Đã tạo bộ sưu tập',
      type: AppFeedbackType.success,
    );
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(collectionSaveProvider(widget.editorKey));
    final busy = operation.isLoading || _picking || _leaving;
    return PopScope(
      canPop: _leaving || (context.canPop() && !_dirty && !busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          toolbarHeight: MediaQuery.textScalerOf(context).scale(18) > 24
              ? 88
              : 64,
          title: Text(_editing ? 'Chỉnh sửa bộ sưu tập' : 'Tạo bộ sưu tập'),
          leading: BackButton(onPressed: busy ? null : _cancel),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.margin),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: context.colors.primary,
                child: Icon(
                  Icons.person_outline,
                  size: 20,
                  color: context.colors.onPrimary,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Form(
            key: _form,
            child: CustomScrollView(
              key: const PageStorageKey('collection-editor-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: AppSpacing.page,
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CollectionCoverPreview(first: _places.firstOrNull),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Thông tin bộ sưu tập',
                          style: context.textStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Tên bộ sưu tập *',
                          style: context.textStyles.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const ValueKey('collection-name'),
                          controller: _name,
                          hintText: 'Ví dụ: Quán ngon cuối tuần',
                          enabled: !busy,
                          validator: validateCollectionName,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(60),
                          ],
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_name.text.characters.length}/60',
                            style: context.textStyles.labelSmall,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Mô tả (không bắt buộc)',
                          style: context.textStyles.labelLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppTextField(
                          key: const ValueKey('collection-description'),
                          controller: _description,
                          hintText: 'Điều gì làm bộ sưu tập này đặc biệt?',
                          enabled: !busy,
                          maxLines: 3,
                          validator: validateCollectionDescription,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(300),
                          ],
                          onChanged: (_) => setState(() {}),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_description.text.characters.length}/300',
                            style: context.textStyles.labelSmall,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.colors.primaryContainer.withValues(
                              alpha: .4,
                            ),
                            borderRadius: AppRadii.inputBorder,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 20,
                                color: context.colors.primary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bộ sưu tập riêng tư',
                                      style: context.textStyles.labelLarge,
                                    ),
                                    Text(
                                      'Chỉ bạn có thể xem và chỉnh sửa bộ sưu tập này.',
                                      style: context.textStyles.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isDemo)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              'Dữ liệu mẫu • Chỉ lưu trong phiên ứng dụng',
                              style: context.textStyles.labelSmall,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Địa điểm trong bộ sưu tập',
                              style: context.textStyles.titleMedium,
                            ),
                            AppBadge(
                              label: '${_places.length} địa điểm',
                              tone: AppBadgeTone.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: 'Thêm địa điểm vào danh sách',
                          icon: Icons.add_circle_outline,
                          variant: AppButtonVariant.outline,
                          expanded: true,
                          onPressed: busy ? null : _pick,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
                if (_places.isEmpty)
                  SliverToBoxAdapter(
                    child: AppEmptyState(
                      icon: Icons.bookmark_border,
                      title: 'Chưa có địa điểm nào',
                      message: 'Thêm những quán bạn muốn lưu vào bộ sưu tập. Bạn cũng có thể thêm sau.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.margin,
                    ),
                    sliver: SliverList.builder(
                      itemCount: _places.length,
                      itemBuilder: (_, index) => CollectionPlaceRow(
                        key: ValueKey(_places[index].id),
                        place: _places[index],
                        first: index == 0,
                        onRemove: busy
                            ? null
                            : () => setState(() => _places.removeAt(index)),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: AppSpacing.page,
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: context.colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Thêm hoặc bỏ địa điểm tại đây không làm thay đổi danh sách Yêu thích và Muốn ghé thăm của bạn.',
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (operation.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              AppErrorMessage.from(
                                operation.error!,
                                fallback: 'Không thể lưu bộ sưu tập. Vui lòng thử lại.',
                              ),
                              style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Material(
            color: context.colors.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.md,
                  AppSpacing.margin,
                  AppSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppButton(
                      key: const ValueKey('save-collection'),
                      label: operation.isLoading
                          ? 'Đang lưu...'
                          : _editing
                          ? 'Lưu thay đổi'
                          : 'Tạo bộ sưu tập',
                      icon: Icons.check,
                      isLoading: operation.isLoading,
                      onPressed: busy || (_editing && !_dirty) ? null : _save,
                    ),
                    TextButton(
                      onPressed: busy ? null : _cancel,
                      child: const Text('Hủy'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
