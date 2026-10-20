import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/auth_validation.dart';
import 'auth_providers.dart';
import 'login_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.returnTo,
    this.action,
    this.scope = 'forgot-password',
  });

  final String? returnTo, action;
  final String scope;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(forgotPasswordControllerProvider(widget.scope).notifier)
        .submit(_email.text);
    if (!mounted ||
        ref.read(forgotPasswordControllerProvider(widget.scope)).hasError) {
      return;
    }
    setState(() => _sent = true);
  }

  void _goLogin() {
    final query = <String, dynamic>{
      'returnTo': ?safeReturnTo(widget.returnTo),
      if (widget.action != null) 'action': widget.action!,
    };
    context.go(AppRoute.login.location(query: query));
  }

  void _resetForm() {
    _email.clear();
    ref.invalidate(forgotPasswordControllerProvider(widget.scope));
    setState(() => _sent = false);
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(forgotPasswordControllerProvider(widget.scope));
    final busy = operation.isLoading;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Quay lại',
                      onPressed: busy ? null : _goLogin,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        'Quên mật khẩu',
                        textAlign: TextAlign.center,
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: context.colors.primary,
                      foregroundColor: context.colors.onPrimary,
                      child: const Icon(Icons.person, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LoginBrand(
                          title: 'Quên mật khẩu?',
                          description: 'Nhập địa chỉ email của bạn, chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu.',
                          middle: const ResetMailIllustration(),
                        ),
                        const SizedBox(height: 20),
                        if (!_sent) _buildForm(context, operation, busy),
                        if (_sent) _buildSuccess(context),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              'Nhớ mật khẩu?',
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: busy ? null : _goLogin,
                              child: const Text('Đăng nhập'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AsyncValue<void> operation,
    bool busy,
  ) => AutofillGroup(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Email', style: context.textStyles.labelMedium),
              Flexible(
                child: Text(
                  'Ví dụ: user@foodreview.vn',
                  textAlign: TextAlign.end,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AppTextField(
            key: const ValueKey('forgot-email'),
            controller: _email,
            hintText: 'Nhập địa chỉ email của bạn',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            enabled: !busy,
            validator: AuthValidation.email,
            onFieldSubmitted: (_) {
              if (!busy) _submit();
            },
          ),
          if (operation.hasError) ...[
            const SizedBox(height: 8),
            LoginError(
              message: AppErrorMessage.from(
                operation.error!,
                fallback: 'Không gửi được hướng dẫn. Vui lòng thử lại.',
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: 'Gửi hướng dẫn đặt lại',
            icon: Icons.send_outlined,
            iconAlignment: IconAlignment.end,
            expanded: true,
            isLoading: busy,
            onPressed: busy ? null : _submit,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerLow,
              borderRadius: AppRadii.cardBorder,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: context.colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chúng tôi sẽ gửi email chứa liên kết đặt lại mật khẩu. '
                    'Vui lòng kiểm tra hộp thư đến và thư mục spam nếu không thấy email.',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSuccess(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLowest,
      borderRadius: AppRadii.cardBorder,
    ),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: context.colors.primaryFixed,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read,
            color: context.colors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kiểm tra email của bạn',
          textAlign: TextAlign.center,
          style: context.textStyles.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Nếu địa chỉ email này đã được đăng ký, bạn sẽ nhận được hướng dẫn đặt lại mật khẩu trong thời gian ngắn.',
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Gửi lại hoặc thử email khác',
          icon: Icons.arrow_back,
          expanded: true,
          variant: AppButtonVariant.outline,
          onPressed: _resetForm,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Quay lại đăng nhập',
          expanded: true,
          onPressed: _goLogin,
        ),
      ],
    ),
  );
}
