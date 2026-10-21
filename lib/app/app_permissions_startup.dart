import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/places/presentation/user_location_controller.dart';

/// Requests foreground location without blocking app UI.
class AppPermissionsStartup extends ConsumerStatefulWidget {
  const AppPermissionsStartup({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppPermissionsStartup> createState() =>
      _AppPermissionsStartupState();
}

class _AppPermissionsStartupState extends ConsumerState<AppPermissionsStartup>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialize();
      }
    });
  }

  Future<void> _initialize() async {
    await ref.read(userLocationControllerProvider.notifier).initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(userLocationControllerProvider.notifier).resumeFromSettings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
