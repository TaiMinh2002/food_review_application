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

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({
    super.key,
    this.returnTo,
    this.action,
    this.scope = 'login',
  });
  final String? returnTo, action;
  final String scope;
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  bool _navigating = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _finish() {
    if (_navigating || ModalRoute.of(context)?.isCurrent != true) return;
    _navigating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
        _navigating = false;
        return;
      }
      TextInput.finishAutofillContext();
      final router = GoRouter.of(context);
      final target = safeReturnTo(widget.returnTo);
      if (router.canPop()) {
        router.pop();
        if (target != null && router.state.uri.toString() != target) {
          router.push(target);
        }
      } else {
        router.go(target ?? AppRoute.home.path);
      }
    });
  }

  void _submit() {
    final session = ref.read(authSessionProvider);
    if (session.isLoading || session.hasError) return;
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(signInControllerProvider(widget.scope).notifier)
        .submit(_email.text, _password.text);
  }

  void _related(AppRoute route) => context.push(
    route.location(
      query: {
        'returnTo': ?safeReturnTo(widget.returnTo),
        if (widget.action == 'favorite') 'action': 'favorite',
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    ref.listen(authSessionProvider, (_, next) {
      if (next.asData?.value != null) _finish();
    });
    if (session.asData?.value != null) _finish();
    final operation = ref.watch(signInControllerProvider(widget.scope));
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
                            child: LoginBrand(),
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
                      const SizedBox(height: 20),
                      const LoginFoodHighlight(),
                      const SizedBox(height: 20),
                      if (widget.action == 'favorite') ...[
                        Text(
                          'Sau đăng nhập, chạm lại biểu tượng tim để lưu quán.',
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
                                'Đăng nhập chưa thành công. Vui lòng thử lại.',
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
                                'Email',
                                style: context.textStyles.labelMedium,
                              ),
                              const SizedBox(height: 6),
                              AppTextField(
                                key: const ValueKey('login-email'),
                                controller: _email,
                                hintText: 'Nhập địa chỉ email của bạn',
                                prefixIcon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                ],
                                enabled: !busy,
                                validator: AuthValidation.email,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Mật khẩu',
                                    style: context.textStyles.labelMedium,
                                  ),
                                  TextButton(
                                    onPressed: busy
                                        ? null
                                        : () =>
                                              _related(AppRoute.forgotPassword),
                                    child: const Text('Quên mật khẩu?'),
                                  ),
                                ],
                              ),
                              AppTextField(
                                key: const ValueKey('login-password'),
                                controller: _password,
                                hintText: 'Nhập mật khẩu',
                                prefixIcon: Icons.lock_outline,
                                isPassword: true,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                enabled: !busy,
                                validator: AuthValidation.password,
                                onFieldSubmitted: (_) {
                                  if (!busy) _submit();
                                },
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                label: operation.isLoading
                                    ? 'Đang đăng nhập...'
                                    : 'Đăng nhập',
                                icon: Icons.arrow_forward,
                                iconAlignment: IconAlignment.end,
                                isLoading: operation.isLoading,
                                onPressed: busy || session.hasError
                                    ? null
                                    : _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            'Chưa có tài khoản?',
                            style: context.textStyles.bodyMedium,
                          ),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => _related(AppRoute.register),
                            child: const Text('Đăng ký ngay'),
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
