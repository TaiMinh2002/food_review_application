import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/auth/domain/auth_repository.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/reviews/domain/review_repository.dart';
import 'package:food_review/features/reviews/presentation/review_providers.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';
import 'package:food_review/features/collections/domain/collection_repository.dart';
import 'package:food_review/features/collections/presentation/collections_controller.dart';
import 'package:food_review/features/notifications/domain/notification_repository.dart';
import 'package:food_review/features/notifications/presentation/notifications_controller.dart';
import 'package:food_review/features/profile/domain/public_reviewer_repository.dart';
import 'package:food_review/features/profile/presentation/public_reviewer_controller.dart';
import 'package:food_review/features/reports/domain/report_repository.dart';
import 'package:food_review/features/reports/presentation/report_controller.dart';
import 'package:food_review/features/profile/domain/profile_repository.dart';
import 'package:food_review/features/profile/presentation/profile_edit_controller.dart';

const authTestUser = UserProfile(id: 'user-a', displayName: 'Người thử nghiệm');

class ControlledAuth implements AuthRepository {
  ControlledAuth({this.user, this.initialReady = true});
  UserProfile? user;
  bool initialReady;
  bool autoSignIn = false;
  int signIns = 0, signOuts = 0;
  int signUps = 0;
  int resetRequests = 0;
  String? email, password, displayName, resetEmail;
  bool autoSignUp = false;
  Completer<void>? pendingSignIn, pendingSignOut, pendingSignUp, pendingReset;
  final events = StreamController<UserProfile?>.broadcast();
  void setUser(UserProfile? value) {
    user = value;
    events.add(value);
  }

  @override
  Stream<UserProfile?> authStateChanges() => Stream.multi((sink) {
    final subscription = events.stream.listen(
      sink.add,
      onError: sink.addError,
      onDone: sink.close,
    );
    sink.onCancel = subscription.cancel;
    if (initialReady) sink.add(user);
  });

  @override
  Future<void> signIn({required String email, required String password}) async {
    signIns++;
    this.email = email;
    this.password = password;
    if (pendingSignIn != null) await pendingSignIn!.future;
    if (autoSignIn) setUser(authTestUser);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (pendingSignOut != null) await pendingSignOut!.future;
    setUser(null);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    signUps++;
    this.email = email;
    this.password = password;
    this.displayName = displayName;
    if (pendingSignUp != null) await pendingSignUp!.future;
    if (autoSignUp) setUser(authTestUser);
  }

  @override
  Future<void> resetPassword({required String email}) async {
    resetRequests++;
    resetEmail = email;
    if (pendingReset != null) await pendingReset!.future;
  }
}

final loginCaptureKey = GlobalKey();
Future<void> loadAuthFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await (FontLoader(
    'Inter',
  )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

Future<ProviderContainer> mountAuth(
  WidgetTester tester,
  ControlledAuth repository, {
  String route = '/login',
  double width = 390,
  double height = 844,
  double scale = 1,
  ThemeMode mode = ThemeMode.light,
  ReviewRepository? reviews,
  CollectionRepository? collections,
  NotificationRepository? notifications,
  PublicReviewerRepository? publicReviewers,
  ReportRepository? reports,
  ProfilePhotoRepository? reportPhotos,
  double? keyboard,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      mapTilesEnabledProvider.overrideWithValue(false),
      if (reviews != null) reviewRepositoryProvider.overrideWithValue(reviews),
      if (collections != null)
        collectionRepositoryProvider.overrideWithValue(collections),
      if (notifications != null)
        notificationRepositoryProvider.overrideWithValue(notifications),
      if (publicReviewers != null)
        publicReviewerRepositoryProvider.overrideWithValue(publicReviewers),
      if (reports != null) reportRepositoryProvider.overrideWithValue(reports),
      if (reportPhotos != null)
        profilePhotoRepositoryProvider.overrideWithValue(reportPhotos),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await repository.events.close();
  });
  container.read(themeModeProvider.notifier).setMode(mode);
  container.read(appRouterProvider).go(route);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: loginCaptureKey,
        child: MediaQuery.fromView(
          view: tester.view,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
                viewInsets: keyboard == null
                    ? null
                    : EdgeInsets.only(bottom: keyboard),
                padding: const EdgeInsets.only(top: 44, bottom: 24),
                viewPadding: const EdgeInsets.only(top: 44, bottom: 24),
              ),
              child: const FoodReviewApp(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> fillLogin(WidgetTester tester) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('login-email')),
      matching: find.byType(TextFormField),
    ),
    '  tester@example.com  ',
  );
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('login-password')),
      matching: find.byType(TextFormField),
    ),
    ' secret ',
  );
}

Future<void> fillRegister(
  WidgetTester tester, {
  bool acceptTerms = true,
}) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('register-name')),
      matching: find.byType(TextFormField),
    ),
    'Người dùng thử',
  );
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('register-email')),
      matching: find.byType(TextFormField),
    ),
    'tester@example.com',
  );
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('register-password')),
      matching: find.byType(TextFormField),
    ),
    'password',
  );
  await tester.enterText(
    find.descendant(
      of: find.byKey(const ValueKey('register-confirmation')),
      matching: find.byType(TextFormField),
    ),
    'password',
  );
  if (acceptTerms) {
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
  }
}
