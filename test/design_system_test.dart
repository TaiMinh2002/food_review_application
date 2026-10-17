import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/errors/app_error_message.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/formatters/app_formatters.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/shared/design_system/design_system.dart';
import 'package:food_review/shared/design_system/design_system_screen.dart';

Widget host(Widget child, {ThemeMode mode = ThemeMode.light}) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: mode,
  home: Scaffold(body: child),
);

void main() {
  test('Error messages expose only intentional user-facing failures', () {
    expect(
      AppErrorMessage.from(Exception('secret backend diagnostics')),
      'Đã xảy ra lỗi. Vui lòng thử lại.',
    );
    expect(
      AppErrorMessage.from(const AppException('raw', code: 'network')),
      contains('kết nối mạng'),
    );
    expect(AppFormatters.priceRange(50000, 150000), '50.000đ - 150.000đ');
    expect(AppFormatters.distance(1200), '1.2 km');
  });

  testWidgets('Loading and disabled buttons do not submit', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        Column(
          children: [
            AppButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () => calls++,
            ),
            const AppButton(label: 'Disabled', onPressed: null),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Đang xử lý...'));
    await tester.tap(find.text('Disabled'));
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('Search clear notifies parent and supports replaced controller', (
    tester,
  ) async {
    final first = TextEditingController(text: 'phở');
    final second = TextEditingController(text: 'cà phê');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    String? query;
    await tester.pumpWidget(
      host(AppSearchField(controller: first, onChanged: (v) => query = v)),
    );
    await tester.tap(find.byTooltip('Xoá nội dung'));
    expect(first.text, isEmpty);
    expect(query, '');
    await tester.pumpWidget(host(AppSearchField(controller: second)));
    first.text = 'detached';
    await tester.pump();
    expect(find.text('cà phê'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Password visibility and validation are interactive', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      host(
        Form(
          key: form,
          child: AppTextField(
            label: 'Mật khẩu',
            isPassword: true,
            validator: (v) => v == null || v.isEmpty ? 'Bắt buộc' : null,
          ),
        ),
      ),
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isFalse,
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Bắt buộc'), findsOneWidget);
  });

  testWidgets(
    'Rating input reports selection; dialog distinguishes cancel/confirm',
    (tester) async {
      var rating = 0;
      bool? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Column(
              children: [
                AppRatingInput(value: rating, onChanged: (v) => rating = v),
                AppButton(
                  label: 'Open',
                  onPressed: () async {
                    result = await showAppConfirmation(
                      context,
                      title: 'Xác nhận',
                      message: 'Bỏ lưu quán?',
                      confirmLabel: 'Xoá bỏ',
                      destructive: true,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('3 sao'));
      expect(rating, 3);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xoá bỏ'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    },
  );

  testWidgets(
    'Runtime theme changes reach existing routes and semantic colors',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FoodReviewApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      var context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(context.semanticColors.canvas, AppSemanticColors.dark.canvas);
      container.read(appRouterProvider).go('/profile');
      await tester.pumpAndSettle();
      context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).brightness, Brightness.dark);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(Theme.of(context).brightness, Brightness.light);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'Full UI Kit fits 320px with large Vietnamese text: ${mode.name}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.6),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const DesignSystemScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var i = 0; i < 35; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -480));
          await tester.pump(const Duration(milliseconds: 500));
          final exception = tester.takeException();
          expect(exception, isNull, reason: 'Scroll $i in ${mode.name}');
        }
        expect(find.text('10 · Thanh điều hướng'), findsOneWidget);
      },
    );
  }
}
