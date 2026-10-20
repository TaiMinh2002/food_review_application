import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../features/places/domain/gallery.dart';
import '../../features/places/presentation/gallery_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/want_to_visit/presentation/want_to_visit_screen.dart';
import '../../features/reviews/presentation/all_reviews_screen.dart';
import '../../features/reviews/presentation/write_review_screen.dart';
import '../../features/reviews/presentation/my_reviews_screen.dart';
import '../../features/reviews/domain/review_feed_repository.dart';
import '../../features/places/presentation/place_detail_screen.dart';
import '../../features/places/presentation/home_screen.dart';
import '../../features/places/presentation/category_screen.dart';
import '../../features/places/presentation/map_screen.dart';
import '../../features/places/presentation/search_screen.dart';
import '../../features/places/presentation/search_filters_screen.dart';
import '../../features/places/domain/place_search.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/collections/presentation/collections_screen.dart';
import '../../features/collections/presentation/collection_editor_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/public_reviewer_screen.dart';
import '../../shared/design_system/design_system_screen.dart';
import '../../shared/widgets/app_message.dart';
import 'app_route.dart';
import 'route_placeholder_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final authRefresh = ValueNotifier(0);
  ref.listen(authSessionProvider, (_, _) => authRefresh.value++);
  ref.onDispose(authRefresh.dispose);
  final router = GoRouter(
    refreshListenable: authRefresh,
    redirect: (_, state) {
      final session = ref.read(authSessionProvider);
      final private = AppRoute.values.any(
        (route) =>
            route.requiresAuth &&
            RegExp('^${route.path.replaceAll(RegExp(r':\w+'), r'[^/]+')}\$')
                .hasMatch(state.uri.path),
      );
      if (private &&
          !session.isLoading &&
          !session.hasError &&
          session.asData?.value == null) {
        return AppRoute.login.location(
          query: {'returnTo': state.uri.toString()},
        );
      }
      return null;
    },
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.home.path,
    errorBuilder: (_, _) => const RouteBackScope(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(alignment: Alignment.centerLeft, child: RouteBackButton()),
              Expanded(child: AppMessage(message: 'Không tìm thấy trang.')),
            ],
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => AppRoute.home.path),
      GoRoute(
        path: '/places',
        redirect: (_, state) =>
            state.uri.replace(path: AppRoute.home.path).toString(),
      ),
      GoRoute(
        path: '/places/:placeId',
        redirect: (_, state) => Uri.parse(
          AppRoute.restaurant.location(
            parameters: {'restaurantId': state.pathParameters['placeId']!},
          ),
        ).replace(query: state.uri.query).toString(),
      ),
      GoRoute(
        path: '/sign-in',
        redirect: (_, state) =>
            state.uri.replace(path: AppRoute.login.path).toString(),
      ),
      GoRoute(
        name: AppRoute.designSystem.name,
        path: AppRoute.designSystem.path,
        builder: (_, _) => const DesignSystemScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.home.name,
                path: AppRoute.home.path,
                // Home keeps quick filtering; submit opens the dedicated search flow.
                builder: (_, _) => const HomeScreen(),
              ),
              GoRoute(
                name: AppRoute.category.name,
                path: AppRoute.category.path,
                builder: (_, state) => RouteBackScope(
                  child: CategoryScreen(
                    categoryId: state.pathParameters['categoryId']!,
                    uri: state.uri,
                    scope: state.pageKey.value,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.map.name,
                path: AppRoute.map.path,
                builder: (_, state) => PlaceMapScreen(
                  restaurantId: state.uri.queryParameters['restaurantId'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.favorites.name,
                path: AppRoute.favorites.path,
                builder: (_, _) => const FavoritesScreen(),
              ),
              GoRoute(
                name: AppRoute.collections.name,
                path: AppRoute.collections.path,
                builder: (_, _) => const CollectionsScreen(),
              ),
              GoRoute(
                name: AppRoute.wantToVisit.name,
                path: AppRoute.wantToVisit.path,
                builder: (_, _) => const WantToVisitScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.profile.name,
                path: AppRoute.profile.path,
                builder: (_, _) => const ProfileScreen(),
              ),
              GoRoute(
                name: AppRoute.settings.name,
                path: AppRoute.settings.path,
                builder: (_, _) => const SettingsScreen(),
              ),
              GoRoute(
                name: AppRoute.myReviews.name,
                path: AppRoute.myReviews.path,
                builder: (_, _) =>
                    const RouteBackScope(child: MyReviewsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: AppRoute.search.name,
        path: AppRoute.search.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => RouteBackScope(
          child: SearchScreen(
            seed: (
              request: PlaceSearchRequest.fromUri(state.uri),
              scope: state.pageKey.value,
            ),
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.filters.name,
        path: AppRoute.filters.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => RouteBackScope(
          child: SearchFiltersScreen(
            initialRequest: PlaceSearchRequest.fromUri(state.uri),
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.restaurant.name,
        path: AppRoute.restaurant.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => RouteBackScope(
          child: PlaceDetailScreen(
            placeId: state.pathParameters['restaurantId']!,
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.reviews.name,
        path: AppRoute.reviews.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => RouteBackScope(
          child: AllReviewsScreen(
            seed: (
              placeId: state.pathParameters['restaurantId']!,
              scope: state.pageKey.value,
              filters: ReviewFilters.fromUri(state.uri),
            ),
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.login.name,
        path: AppRoute.login.path,
        parentNavigatorKey: rootNavigatorKey,
        redirect: (_, state) {
          final requested = state.uri.queryParameters['returnTo'];
          if (requested == null || safeReturnTo(requested) != null) return null;
          final query = Map<String, String>.of(state.uri.queryParameters)
            ..remove('returnTo');
          return state.uri.replace(queryParameters: query).toString();
        },
        builder: (_, state) => RouteBackScope(
          child: SignInScreen(
            returnTo: safeReturnTo(state.uri.queryParameters['returnTo']),
            action: state.uri.queryParameters['action'],
            scope: state.pageKey.value,
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.register.name,
        path: AppRoute.register.path,
        parentNavigatorKey: rootNavigatorKey,
        redirect: (_, state) {
          final requested = state.uri.queryParameters['returnTo'];
          if (requested == null || safeReturnTo(requested) != null) return null;
          final query = Map<String, String>.of(state.uri.queryParameters)
            ..remove('returnTo');
          return state.uri.replace(queryParameters: query).toString();
        },
        builder: (_, state) => RouteBackScope(
          child: RegisterScreen(
            returnTo: safeReturnTo(state.uri.queryParameters['returnTo']),
            action: state.uri.queryParameters['action'],
            scope: state.pageKey.value,
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.forgotPassword.name,
        path: AppRoute.forgotPassword.path,
        parentNavigatorKey: rootNavigatorKey,
        redirect: (_, state) {
          final requested = state.uri.queryParameters['returnTo'];
          if (requested == null || safeReturnTo(requested) != null) return null;
          final query = Map<String, String>.of(state.uri.queryParameters)
            ..remove('returnTo');
          return state.uri.replace(queryParameters: query).toString();
        },
        builder: (_, state) => RouteBackScope(
          child: ForgotPasswordScreen(
            returnTo: safeReturnTo(state.uri.queryParameters['returnTo']),
            action: state.uri.queryParameters['action'],
            scope: state.pageKey.value,
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.gallery.name,
        path: AppRoute.gallery.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => RouteBackScope(
          child: GalleryScreen(
            request: GalleryRequest.fromUri(
              state.pathParameters['restaurantId']!,
              state.uri,
            ),
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.createReview.name,
        path: AppRoute.createReview.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => RouteBackScope(
          child: WriteReviewScreen(
            placeId: state.pathParameters['restaurantId']!,
            scope: state.pageKey.value,
          ),
        ),
      ),
      GoRoute(
        name: AppRoute.editReview.name,
        path: AppRoute.editReview.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) {
          final placeId = state.uri.queryParameters['restaurantId'];
          final reviewId = state.pathParameters['reviewId'];
          return RouteBackScope(
            child: placeId == null || placeId.isEmpty || reviewId == null
                ? const Scaffold(
                    body: SafeArea(
                      child: AppMessage(message: 'Không tìm thấy đánh giá.'),
                    ),
                  )
                : WriteReviewScreen(
                    placeId: placeId,
                    reviewId: reviewId,
                    scope: state.pageKey.value,
                  ),
          );
        },
      ),
      GoRoute(
        name: AppRoute.editProfile.name,
        path: AppRoute.editProfile.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        name: AppRoute.createCollection.name,
        path: AppRoute.createCollection.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) =>
            CollectionEditorScreen(scope: state.pageKey.value),
      ),
      GoRoute(
        name: AppRoute.editCollection.name,
        path: AppRoute.editCollection.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => CollectionEditorScreen(
          collectionId: state.pathParameters['collectionId']!,
          scope: state.pageKey.value,
        ),
      ),
      GoRoute(
        name: AppRoute.notifications.name,
        path: AppRoute.notifications.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const RouteBackScope(child: NotificationsScreen()),
      ),
      GoRoute(
        name: AppRoute.reviewer.name,
        path: AppRoute.reviewer.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => RouteBackScope(
          child: PublicReviewerScreen(userId: state.pathParameters['userId']!),
        ),
      ),
      for (final route in AppRoute.values)
        if (route.task != null &&
            route != AppRoute.map &&
            route != AppRoute.register &&
            route != AppRoute.forgotPassword &&
            route != AppRoute.createReview &&
            route != AppRoute.editReview &&
            route != AppRoute.myReviews &&
            route != AppRoute.wantToVisit &&
            route != AppRoute.notifications)
          GoRoute(
            name: route.name,
            path: route.path,
            parentNavigatorKey: rootNavigatorKey,
            // Denied until T26 verifies backend roles; no admin data is loaded.
            builder: (_, state) => RouteBackScope(
              child: route.requiresAuth
                  ? AuthGate(
                      returnTo: state.uri.toString(),
                      child: RoutePlaceholderScreen(route: route),
                    )
                  : RoutePlaceholderScreen(route: route),
            ),
          ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
