import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_message.dart';
import 'app_route.dart';

void backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoute.home.path);
  }
}

class RouteBackButton extends StatelessWidget {
  const RouteBackButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BackButton(onPressed: () => backOrHome(context));
}

/// Platform Back falls back to Home when a direct link has no previous page.
class RouteBackScope extends StatelessWidget {
  const RouteBackScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: context.canPop(),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) context.go(AppRoute.home.path);
    },
    child: child,
  );
}

class RoutePlaceholderScreen extends StatelessWidget {
  const RoutePlaceholderScreen({super.key, required this.route});
  final AppRoute route;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(route.title), leading: const RouteBackButton()),
    body: AppMessage(
      message: route.isAdmin
          ? 'Không có quyền truy cập. Quyền quản trị chưa được xác minh.'
          : 'Chức năng chưa triển khai · ${route.task}.',
    ),
  );
}
