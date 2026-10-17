import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

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
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: destinations,
    ),
  );
}
