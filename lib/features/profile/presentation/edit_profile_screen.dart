import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';
import 'profile_edit_controller.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final user = !session.isLoading && !session.hasError
        ? session.asData?.value
        : null;
    return AuthGate(
      returnTo: AppRoute.editProfile.path,
      child: user == null
          ? const SizedBox.shrink()
          : _ProfileForm(key: ValueKey(user.id), user: user),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({super.key, required this.user});
  final UserProfile user;
  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.displayName);
  late final _originalPhotoUrl = widget.user.photoUrl;
  ProfilePhoto? _photo;
  bool _removed = false, _picking = false;
  String? _photoError;
  bool get _dirty =>
      _name.text.trim() != widget.user.displayName ||
      _photo != null ||
      (_removed && _originalPhotoUrl != null);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoute.profile.path);
    }
  }

  Future<void> _cancel() async {
    if (_dirty) {
      final discard = await showAppConfirmation(
        context,
        title: 'Bỏ thay đổi?',
        message: 'Các thay đổi hồ sơ chưa lưu sẽ bị bỏ.',
        confirmLabel: 'Bỏ thay đổi',
        cancelLabel: 'Tiếp tục sửa',
      );
      if (!discard || !mounted) return;
    }
    _leave();
  }

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final photo = await ref.read(profilePhotoRepositoryProvider).pickPhoto();
      if (mounted && photo != null) {
        setState(() {
          _photo = photo;
          _removed = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _photoError = AppErrorMessage.from(
            error,
            fallback: 'Không chọn được ảnh. Vui lòng thử lại.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(profileEditControllerProvider(widget.user.id).notifier)
        .save(
          displayName: _name.text,
          photoUrl: _removed ? null : _originalPhotoUrl,
          newPhoto: _photo,
        );
    if (!mounted || !success) return;
    AppToast.show(
      context,
      'Đã cập nhật hồ sơ thành công!',
      type: AppFeedbackType.success,
    );
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(profileEditControllerProvider(widget.user.id));
    final busy = operation.isLoading || _picking;
    return PopScope(
      canPop: context.canPop() && !busy && !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: busy ? null : _cancel),
          title: const Text('Edit Profile'),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.margin),
              child: CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 18),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: _AvatarEditor(
                          name: _name.text,
                          photo: _photo,
                          url: _removed ? null : _originalPhotoUrl,
                          onPick: busy ? null : _pick,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: busy ? null : _pick,
                            icon: const Icon(
                              Icons.add_a_photo_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _picking ? 'Đang chọn ảnh…' : 'Thay đổi ảnh',
                            ),
                          ),
                          TextButton(
                            onPressed:
                                busy ||
                                    (_photo == null &&
                                        (_removed || _originalPhotoUrl == null))
                                ? null
                                : () => setState(() {
                                    _photo = null;
                                    _removed = true;
                                  }),
                            style: TextButton.styleFrom(
                              foregroundColor: context.colors.error,
                            ),
                            child: const Text('Xóa ảnh'),
                          ),
                        ],
                      ),
                      if (_photoError != null)
                        Text(
                          _photoError!,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      _ProfileField(
                        controller: _name,
                        label: 'Tên hiển thị',
                        helper:
                            'Tên mọi người sẽ nhìn thấy trên hồ sơ của bạn.',
                        validator: validateProfileName,
                        enabled: !busy,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _ProfileField(
                        label: 'Tên người dùng',
                        hintText: 'Chưa thiết lập',
                        prefixIcon: Icons.alternate_email,
                        enabled: false,
                        helper: 'Tên người dùng giúp bạn bè tìm thấy bạn qua thanh tìm kiếm.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _ProfileField(
                        label: 'Giới thiệu',
                        hintText: 'Chia sẻ sở thích ẩm thực với cộng đồng',
                        maxLines: 3,
                        enabled: false,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _ProfileField(
                        label: 'Khu vực (Không bắt buộc)',
                        hintText: 'Chưa thiết lập',
                        prefixIcon: Icons.location_on_outlined,
                        enabled: false,
                        helper: 'Hiển thị thành phố để nhận gợi ý quán ăn và đặc sản.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        color: context.colors.surfaceContainerLow,
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'Hiện hỗ trợ lưu tên và ảnh đại diện. Tên người dùng, giới thiệu và khu vực sẽ mở khi có dịch vụ hồ sơ.',
                          ),
                        ),
                      ),
                      if (operation.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Text(
                            AppErrorMessage.from(
                              operation.error!,
                              fallback:
                                  'Không lưu được hồ sơ. Vui lòng thử lại.',
                            ),
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'Lưu thay đổi',
                        icon: Icons.save_outlined,
                        expanded: true,
                        isLoading: operation.isLoading,
                        onPressed: busy || !_dirty ? null : _save,
                      ),
                      const SizedBox(height: AppSpacing.sm),
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
      ),
    );
  }
}

class _AvatarEditor extends StatelessWidget {
  const _AvatarEditor({
    required this.name,
    required this.url,
    required this.photo,
    required this.onPick,
  });
  final String name;
  final String? url;
  final ProfilePhoto? photo;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.bottomRight,
    children: [
      if (photo == null)
        AppAvatar(name: name, imageUrl: url, size: AppAvatarSize.profile)
      else
        ClipOval(
          child: Image.memory(
            photo!.bytes,
            width: 112,
            height: 112,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.square(
              dimension: 112,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      IconButton.filled(
        tooltip: 'Chọn ảnh đại diện',
        style: IconButton.styleFrom(
          backgroundColor: context.colors.primary,
          foregroundColor: context.colors.onPrimary,
        ),
        onPressed: onPick,
        icon: const Icon(Icons.photo_camera_outlined, size: 20),
      ),
    ],
  );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    this.controller,
    this.hintText,
    this.helper,
    this.prefixIcon,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
  });
  final String label;
  final String? hintText, helper;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: context.textStyles.bodyMedium),
      const SizedBox(height: AppSpacing.sm),
      Semantics(
        label: label,
        child: AppTextField(
          controller: controller,
          hintText: hintText,
          enabled: enabled,
          prefixIcon: prefixIcon,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
        ),
      ),
      if (helper != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          helper!,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}
