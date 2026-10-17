import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_shell.dart';
import '../../shared/design_system/design_system_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/places/presentation/place_detail_screen.dart';
import '../../features/places/presentation/places_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/widgets/app_message.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/places',
    errorBuilder: (context, state) =>
        const Scaffold(body: AppMessage(message: 'Không tìm thấy trang.')),
    routes: [
      GoRoute(
        path: '/design-system',
        builder: (context, state) => const DesignSystemScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/places',
                builder: (context, state) => const PlacesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/places/:placeId',
        builder: (context, state) =>
            PlaceDetailScreen(placeId: state.pathParameters['placeId']!),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
