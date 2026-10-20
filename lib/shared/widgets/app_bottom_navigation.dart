import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

const mainAppDestinations = [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Trang chủ',
  ),
  NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Bản đồ'),
  NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Yêu thích'),
  NavigationDestination(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
];

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      boxShadow: [
        BoxShadow(
          color: context.colors.shadow.withValues(alpha: .05),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: NavigationBar(
      height: 64,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: destinations,
    ),
  );
}
