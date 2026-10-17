import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Follows the device by default. Override at ProviderScope for previews/tests.
final themeModeProvider = NotifierProvider<AppThemeMode, ThemeMode>(
  AppThemeMode.new,
);

class AppThemeMode extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void setMode(ThemeMode mode) => state = mode;
}
