# Repository Guidelines

## Mandatory Rules

Read and follow [rule.md](rule.md) before every task. It defines architecture, reuse, the 700-line file limit, light/dark theming, and branch naming. Feature branches use `feat/`, never `codex/`.

## Project Structure & Module Organization

- `lib/app/`: application root and navigation shell; `lib/core/`: router, configuration, themes, formatting, and errors.
- `lib/features/`: feature modules such as `places`, `favorites`, `auth`, `reviews`, and `profile`, organized into `domain/`, `data/`, and `presentation/`.
- `lib/shared/`: reusable widgets and the shared design system. `assets/fonts/` bundles Inter and its license.
- `test/`: domain, widget, and design-system tests. Native projects live in `android/` and `ios/`.
- `docs/`: architecture, backend setup, routing flows, and the UI implementation plan. `config/` contains public client configuration templates.

## Build, Test, and Development Commands

Use Flutter **3.47.5**, matching CI, and the Dart constraint in `pubspec.yaml`.

```sh
flutter pub get                         # Install locked dependencies
cp config/app_config.example.json config/app_config.local.json
flutter run --dart-define-from-file=config/app_config.local.json
dart format lib test                   # Format Dart sources
dart format --output=none --set-exit-if-changed lib test
flutter analyze                        # Run static analysis and lints
flutter test                           # Run all automated tests
flutter build apk --debug               # Build an Android debug APK
```

Firebase initializes at startup. Follow `docs/BACKEND_SETUP.md` for native configuration; web requires additional Firebase initialization configuration.

## Coding Style & Architecture

Use Dart formatting, two-space indentation, `snake_case.dart` filenames, `PascalCase` types, and `camelCase` members. Follow `flutter_lints` in `analysis_options.yaml`.

Keep dependencies flowing **Screen → Riverpod provider → repository contract → data implementation**. Domain models stay independent of Firebase SDKs. Reuse shared components and theme tokens; handle loading, empty, error, and retry states. Dispose controllers and subscriptions appropriately.

## Testing Guidelines

Use `flutter_test`; name files `*_test.dart` and describe observable behavior in test names. Override repository providers for deterministic widget tests. Cover changed navigation, validation, state synchronization, and failure paths. No numeric coverage threshold is configured. CI requires formatting, analysis, and tests to pass. For UI changes, compare screenshots with the relevant Stitch design and check small screens, text scaling, and both themes.

## Commit & Pull Request Guidelines

Use focused commits with concise imperative messages such as `feat:`, `fix:`, or `docs:`. PRs describe the problem, behavior, validation, relevant issues, UI screenshots, and incomplete integrations.

## Security & Configuration

Keep local configuration, credentials, signing keys, and service accounts out of Git. Client configuration cannot hide server secrets. Enforce ownership and admin permissions in backend rules, alongside UI guards. Commit `pubspec.lock` for reproducible dependency resolution.
