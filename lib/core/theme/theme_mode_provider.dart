import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemeRepository {
  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
}

class SharedPreferencesThemeRepository implements ThemeRepository {
  SharedPreferencesThemeRepository(this._prefs);
  final SharedPreferences _prefs;

  static const key = 'app_theme_mode';

  @override
  ThemeMode getThemeMode() {
    final value = _prefs.getString(key);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(key, value);
  }
}

class InMemoryThemeRepository implements ThemeRepository {
  InMemoryThemeRepository([this._mode = ThemeMode.system]);
  ThemeMode _mode;

  @override
  ThemeMode getThemeMode() => _mode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _mode = mode;
  }
}

/// Optional SharedPreferences instance. Overridden at app launch via ProviderScope.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

/// Theme repository provider. Uses SharedPreferences if available, otherwise in-memory.
final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (prefs != null) {
    return SharedPreferencesThemeRepository(prefs);
  }
  return InMemoryThemeRepository();
});

/// Follows the device by default or restored from ThemeRepository.
final themeModeProvider = NotifierProvider<AppThemeMode, ThemeMode>(
  AppThemeMode.new,
);

class AppThemeMode extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final repository = ref.watch(themeRepositoryProvider);
    return repository.getThemeMode();
  }

  void setMode(ThemeMode mode) {
    state = mode;
    ref.read(themeRepositoryProvider).setThemeMode(mode);
  }
}
