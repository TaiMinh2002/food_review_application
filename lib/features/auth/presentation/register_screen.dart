import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/auth_validation.dart';
import 'auth_providers.dart';
import 'login_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({
    super.key,
    this.returnTo,
    this.action,
    this.scope = 'register',
  });

  final String? returnTo, action;
  final String scope;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _termsAccepted = false;
  bool _navigating = false, _submitted = false;

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = ref.read(authSessionProvider);
    if (session.isLoading || session.hasError) return;
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final controller = ref.read(
      registerControllerProvider(widget.scope).notifier,
    );
    setState(() => _submitted = true);
    await controller.submit(
      displayName: _displayName.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted ||
        ref.read(registerControllerProvider(widget.scope)).hasError) {
      return;
    }
    if (ref.read(authSessionProvider).asData?.value != null) _finish();
  }

  void _finish() {
    if (_navigating || !mounted) return;
    _navigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TextInput.finishAutofillContext();
      final router = GoRouter.of(context);
      final target = safeReturnTo(widget.returnTo);
      if (target != null && router.canPop()) {
        router.pop();
        if (router.state.uri.toString() != target) router.push(target);
      } else {
        router.go(target ?? AppRoute.home.path);
      }
    });
  }

  void _openLogin() {
    context.push(
      AppRoute.login.location(
        query: {
          'returnTo': ?safeReturnTo(widget.returnTo),
          if (widget.action != null) 'action': widget.action!,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final operation = ref.watch(registerControllerProvider(widget.scope));
    ref.listen(authSessionProvider, (_, next) {
      if (_submitted &&
          next.asData?.value != null &&
          operation.hasValue &&
          !operation.isLoading &&
          !operation.hasError) {
        _finish();
      }
    });
    final busy = operation.isLoading || session.isLoading || _navigating;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 440,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: LoginBrand(
                              title: 'Tạo tài khoản',
                              description: 'Tham gia cộng đồng khám phá và chia sẻ những quán ăn tuyệt vời.',
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            child: IconButton(
                              tooltip: 'Quay lại',
                              onPressed: () => backOrHome(context),
                              icon: const Icon(Icons.arrow_back),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (widget.action == 'favorite' ||
                          widget.action == 'want_to_visit') ...[
                        Text(
                          widget.action == 'want_to_visit'
                              ? 'Sau khi đăng ký, chạm lại biểu tượng lưu để thêm quán.'
                              : 'Sau khi đăng ký, chạm lại biểu tượng tim để lưu quán.',
                          style: context.textStyles.bodySmall,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (session.hasError) ...[
                        LoginError(
                          message: AppErrorMessage.from(
                            session.error!,
                            fallback: 'Không kiểm tra được phiên đăng nhập.',
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.invalidate(authSessionProvider),
                          child: const Text('Thử lại phiên đăng nhập'),
                        ),
                      ],
                      if (operation.hasError) ...[
                        LoginError(
                          message: AppErrorMessage.from(
                            operation.error!,
                            fallback:
                                'Không tạo được tài khoản. Vui lòng thử lại.',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AutofillGroup(
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Tên hiển thị',
                                style: context.textStyles.labelMedium,
                              ),
                              const SizedBox(height: 6),
                              AppTextField(
                                key: const ValueKey('register-name'),
                                controller: _displayName,
                                hintText: 'Nhập tên của bạn',
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                enabled: !busy,
                                validator: AuthValidation.displayName,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Email',
                                style: context.textStyles.labelMedium,
                              ),
                              const SizedBox(height: 6),
                              AppTextField(
                                key: const ValueKey('register-email'),
                                controller: _email,
                                hintText: 'Nhập địa chỉ email của bạn',
                                prefixIcon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                enabled: !busy,
                                validator: AuthValidation.email,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Mật khẩu',
                                style: context.textStyles.labelMedium,
                              ),
                              const SizedBox(height: 6),
                              AppTextField(
                                key: const ValueKey('register-password'),
                                controller: _password,
                                hintText: 'Tạo mật khẩu',
                                helperText: 'Mật khẩu nên có ít nhất 8 ký tự.',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                enabled: !busy,
                                validator: AuthValidation.registrationPassword,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Xác nhận mật khẩu',
                                style: context.textStyles.labelMedium,
                              ),
                              const SizedBox(height: 6),
                              AppTextField(
                                key: const ValueKey('register-confirmation'),
                                controller: _confirmation,
                                hintText: 'Nhập lại mật khẩu',
                                prefixIcon: Icons.lock_clock_outlined,
                                isPassword: true,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                enabled: !busy,
                                validator: (value) =>
                                    AuthValidation.passwordConfirmation(
                                      value,
                                      _password.text,
                                    ),
                                onFieldSubmitted: (_) {
                                  if (!busy) _submit();
                                },
                              ),
                              const SizedBox(height: 12),
                              FormField<bool>(
                                initialValue: _termsAccepted,
                                validator: (_) =>
                                    AuthValidation.terms(_termsAccepted),
                                builder: (field) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value: _termsAccepted,
                                          onChanged: busy
                                              ? null
                                              : (value) {
                                                  setState(
                                                    () => _termsAccepted =
                                                        value ?? false,
                                                  );
                                                  field.didChange(
                                                    _termsAccepted,
                                                  );
                                                },
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            child: Text.rich(
                                              TextSpan(
                                                text: 'Tôi đồng ý với ',
                                                style: context
                                                    .textStyles
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: context
                                                          .colors
                                                          .onSurfaceVariant,
                                                    ),
                                                children: [
                                                  TextSpan(
                                                    text: 'Điều khoản sử dụng',
                                                    style: context
                                                        .textStyles
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: context
                                                              .colors
                                                              .primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  const TextSpan(text: ' và '),
                                                  TextSpan(
                                                    text: 'Chính sách quyền riêng tư',
                                                    style: context
                                                        .textStyles
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: context
                                                              .colors
                                                              .primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                  const TextSpan(text: '.'),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (field.hasError)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: Text(
                                          field.errorText!,
                                          style: context.textStyles.bodySmall
                                              ?.copyWith(
                                                color: context.colors.error,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              AppButton(
                                label: 'Đăng ký',
                                icon: Icons.arrow_forward,
                                iconAlignment: IconAlignment.end,
                                expanded: true,
                                isLoading: operation.isLoading,
                                onPressed: busy || session.hasError
                                    ? null
                                    : _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            'Đã có tài khoản?',
                            style: context.textStyles.bodyMedium,
                          ),
                          TextButton(
                            onPressed: busy ? null : _openLogin,
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
        ),
      ),
    );
  }
}
