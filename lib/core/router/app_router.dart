import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/reviews/presentation/all_reviews_screen.dart';
import '../../features/reviews/domain/review_feed_repository.dart';
import '../../features/places/presentation/place_detail_screen.dart';
import '../../features/places/presentation/home_screen.dart';
import '../../features/places/presentation/category_screen.dart';
import '../../features/places/presentation/map_screen.dart';
import '../../features/places/presentation/search_screen.dart';
import '../../features/places/presentation/search_filters_screen.dart';
import '../../features/places/domain/place_search.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/design_system/design_system_screen.dart';
import '../../shared/widgets/app_message.dart';
import 'app_route.dart';
import 'route_placeholder_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
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
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoute.profile.name,
                path: AppRoute.profile.path,
                builder: (_, _) => const ProfileScreen(),
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
        builder: (_, _) => const RouteBackScope(child: SignInScreen()),
      ),
      for (final route in AppRoute.values)
        if (route.task != null && route != AppRoute.map)
          GoRoute(
            name: route.name,
            path: route.path,
            parentNavigatorKey: rootNavigatorKey,
            // Denied until T26 verifies backend roles; no admin data is loaded.
            builder: (_, _) =>
                RouteBackScope(child: RoutePlaceholderScreen(route: route)),
          ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
