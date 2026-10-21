import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../profile/presentation/profile_edit_controller.dart';
import '../domain/report_repository.dart';
import 'report_controller.dart';
import 'report_widgets.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key, required this.uri, required this.scope});
  final Uri uri;
  final String scope;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = parseReportTarget(uri);
    final session = ref.watch(authSessionProvider);
    final user = session.isLoading || session.hasError
        ? null
        : session.asData?.value;
    if (target == null) {
      return const _ReportStatus(
        message: 'Không xác định được nội dung cần báo cáo. Vui lòng mở báo cáo từ quán, bài đánh giá hoặc hồ sơ.',
      );
    }
    return AuthGate(
      returnTo: uri.toString(),
      child: user == null
          ? const SizedBox.shrink()
          : _ReportLoader(
              key: ValueKey((user.id, target, scope)),
              reportKey: (ownerId: user.id, target: target, scope: scope),
            ),
    );
  }
}

class _ReportLoader extends ConsumerWidget {
  const _ReportLoader({super.key, required this.reportKey});
  final ReportKey reportKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref
          .watch(reportTargetProvider(reportKey))
          .when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            loading: () => const _ReportStatus(loading: true),
            error: (error, _) => _ReportStatus(
              message: AppErrorMessage.from(
                error,
                fallback: 'Không tải được nội dung. Vui lòng thử lại.',
              ),
              onRetry: () => ref.invalidate(reportTargetProvider(reportKey)),
            ),
            data: (value) => value == null
                ? const _ReportStatus(
                    message: 'Nội dung không tồn tại hoặc không còn khả dụng để báo cáo.',
                  )
                : _ReportForm(reportKey: reportKey, value: value),
          );
}

class _ReportStatus extends StatelessWidget {
  const _ReportStatus({this.loading = false, this.message = '', this.onRetry});
  final bool loading;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => RouteBackScope(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo nội dung'),
        leading: const RouteBackButton(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: loading
              ? const AppSkeleton(height: 240)
              : onRetry != null
              ? AppErrorState(message: message, onRetry: onRetry)
              : AppEmptyState(
                  title: 'Không thể mở báo cáo',
                  message: message,
                  icon: Icons.flag_outlined,
                ),
        ),
      ),
    ),
  );
}

class _ReportForm extends ConsumerStatefulWidget {
  const _ReportForm({required this.reportKey, required this.value});
  final ReportKey reportKey;
  final ReportContext value;
  @override
  ConsumerState<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends ConsumerState<_ReportForm> {
  final _description = TextEditingController();
  final _reasonKey = GlobalKey();
  final _photos = <ReportEvidence>[];
  ReportReason? _reason;
  String? _photoError;
  bool _reasonError = false,
      _picking = false,
      _leaving = false,
      _confirming = false;
  bool get _dirty =>
      _reason != null || _description.text.isNotEmpty || _photos.isNotEmpty;
  bool get _sameSession {
    final session = ref.read(authSessionProvider);
    return !session.isLoading &&
        !session.hasError &&
        session.asData?.value?.id == widget.reportKey.ownerId;
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _leave() {
    if (_leaving) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.canPop() ? context.pop() : context.go(AppRoute.home.path);
    });
  }

  Future<void> _cancel() async {
    if (_confirming ||
        _picking ||
        ref.read(reportSubmitProvider(widget.reportKey)).isLoading) {
      return;
    }
    if (_dirty) {
      _confirming = true;
      final discard = await showAppConfirmation(
        context,
        title: 'Bỏ báo cáo đang soạn?',
        message: 'Lý do, mô tả và ảnh đã chọn sẽ không được lưu.',
        confirmLabel: 'Bỏ báo cáo',
        cancelLabel: 'Tiếp tục soạn',
      );
      if (!mounted || !_sameSession) return;
      _confirming = false;
      if (!discard) return;
    }
    _leave();
  }

  Future<void> _pick() async {
    if (_picking || _photos.length >= 3) return;
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final photo = await ref.read(profilePhotoRepositoryProvider).pickPhoto();
      if (!mounted || !_sameSession || photo == null) return;
      final evidence = ReportEvidence(bytes: photo.bytes, name: photo.name);
      final error = validateReportEvidence(evidence);
      if (error != null) throw FormatException(error);
      if (!_photos.any(
        (existing) => listEquals(existing.bytes, evidence.bytes),
      )) {
        setState(() => _photos.add(evidence));
      }
    } catch (error) {
      if (mounted && _sameSession) {
        setState(
          () => _photoError = error is FormatException
              ? error.message
              : AppErrorMessage.from(
                  error,
                  fallback: 'Không chọn được ảnh. Vui lòng thử lại.',
                ),
        );
      }
    } finally {
      if (mounted && _sameSession) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_reason == null) {
      setState(() => _reasonError = true);
      final reasonContext = _reasonKey.currentContext;
      if (reasonContext != null) {
        await Scrollable.ensureVisible(
          reasonContext,
          duration: const Duration(milliseconds: 200),
        );
      }
      return;
    }
    if (!_sameSession) return;
    await ref
        .read(reportSubmitProvider(widget.reportKey).notifier)
        .submit(
          ReportDraft(
            target: widget.reportKey.target,
            reason: _reason!,
            description: _description.text,
            evidence: _photos,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(reportSubmitProvider(widget.reportKey));
    final receipt = operation.asData?.value;
    final busy = operation.isLoading || _picking || _leaving;
    final isDemo = ref.watch(reportRepositoryProvider).isDemo;
    return PopScope(
      canPop: _leaving || (context.canPop() && !_dirty && !busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) {
          receipt != null ? _leave() : _cancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Báo cáo nội dung', maxLines: 2),
          toolbarHeight: 56 * MediaQuery.textScalerOf(context).scale(14) / 14,
          leading: BackButton(
            onPressed: busy
                ? null
                : receipt != null
                ? _leave
                : _cancel,
          ),
        ),
        body: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: receipt != null
                    ? AppEmptyState(
                        icon: Icons.task_alt,
                        title: receipt.isDemo
                            ? 'Đã lưu báo cáo minh họa'
                            : 'Đã gửi báo cáo',
                        message: receipt.isDemo
                            ? 'Báo cáo chỉ lưu trong phiên ứng dụng, chưa gửi đến đội ngũ kiểm duyệt.'
                            : 'Cảm ơn bạn đã gửi báo cáo. Chúng tôi sẽ xem xét nội dung này.',
                        actionLabel: 'Đóng & Quay lại',
                        onAction: _leave,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ReportContextCard(value: widget.value),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Lý do báo cáo *',
                            key: _reasonKey,
                            style: context.textStyles.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Material(
                            color: context.colors.surface,
                            borderRadius: AppRadii.inputBorder,
                            child: RadioGroup<ReportReason>(
                              groupValue: _reason,
                              onChanged: busy
                                  ? (_) {}
                                  : (value) => setState(() {
                                      _reason = value;
                                      _reasonError = false;
                                    }),
                              child: Column(
                                children: [
                                  for (final reason in ReportReason.values)
                                    RadioListTile<ReportReason>(
                                      value: reason,
                                      dense: true,
                                      enabled: !busy,
                                      controlAffinity:
                                          ListTileControlAffinity.trailing,
                                      title: Text(
                                        reason.label,
                                        style: context.textStyles.bodyMedium,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_reasonError)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: Text(
                                'Vui lòng chọn lý do báo cáo.',
                                style: context.textStyles.bodyMedium?.copyWith(
                                  color: context.colors.error,
                                ),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Mô tả chi tiết (không bắt buộc)',
                            style: context.textStyles.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            key: const ValueKey('report-description'),
                            controller: _description,
                            enabled: !busy,
                            maxLines: 4,
                            keyboardType: TextInputType.multiline,
                            hintText: 'Mô tả cụ thể vấn đề bạn muốn báo cáo...',
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(500),
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_description.text.characters.length}/500',
                              style: context.textStyles.bodySmall,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Không chia sẻ thông tin cá nhân nhạy cảm.',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ReportEvidencePicker(
                            photos: _photos,
                            busy: busy,
                            onAdd: _pick,
                            onRemove: (index) => setState(() {
                              _photos.removeAt(index);
                              _photoError = null;
                            }),
                          ),
                          if (_picking)
                            const LinearProgressIndicator(
                              semanticsLabel: 'Đang chọn ảnh minh chứng',
                            ),
                          if (_photoError != null)
                            Text(
                              _photoError!,
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: context.colors.error,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.xl),
                          ReportNotice(isDemo: isDemo),
                          if (operation.hasError)
                            AppErrorState(
                              title: 'Chưa gửi được báo cáo',
                              message: AppErrorMessage.from(
                                operation.error!,
                                fallback: 'Vui lòng thử lại. Nội dung đã soạn được giữ nguyên.',
                              ),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: 'Gửi báo cáo',
                            isLoading: operation.isLoading,
                            onPressed: busy ? null : _submit,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: busy ? null : _cancel,
                            child: const Text('Hủy bỏ'),
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
