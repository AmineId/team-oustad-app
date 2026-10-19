# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter gym-management client ("Team Fitness") for Android, iOS, Web, Windows, macOS, Linux and smartwatch screen sizes. It talks to a separate Express + Prisma/PostgreSQL backend (not in this repo); the REST contract is documented in `swagger.yml`. Docs and code comments are largely in French.

## Commands

```bash
flutter pub get                         # install deps
flutter analyze --fatal-infos           # what CI runs — infos fail the PR build
dart format .
flutter test                            # all tests
flutter test test/widget_test.dart      # single file
flutter test --plain-name "<name>"      # single test by name
flutter run -d windows|chrome|emulator-5554 [--dart-define=ENVIRONMENT=pprod|prod]
flutter build apk --release --dart-define=ENVIRONMENT=prod
```

iOS can't be built from this (WSL/Windows) machine: `.github/workflows/ios-build.yml` (manual dispatch) builds an unsigned `.ipa` on macOS, and `scripts/ios-install.sh` signs + installs it on a USB iPhone with xtool — see `docs/ios/IOS_XTOOL.md`.

`scripts.ps1` (PowerShell) and `Makefile` wrap the same commands (`.\scripts.ps1 run-android-pprod`, `.\scripts.ps1 run-windows -Url http://192.168.1.50:3000`, etc.).

One-off PowerShell scripts (`bump-version`, `deploy-web`, `setup-play-store-secrets`, `test-design-system`) live in `scripts/` and use paths relative to the repo root, so run them from the root (`.\scripts\deploy-web.ps1`). Docs are grouped by topic under `docs/` (`architecture/`, `design/`, `features/`, `notifications/`, `play-store/`, `release/`, `ios/`); `docs/index.html` is the browsable overview.

Note: `test/widget_test.dart` is still the default Flutter counter template and does not match the app; `test/screens` and `test/widgets` are empty.

## Environment configuration

Everything is selected at build time via `--dart-define`, never hardcoded per build:

- `ENVIRONMENT=dev|pprod|prod` (default `dev`) → `AppConfig.fromEnvironment()` in `lib/core/config/app_config.dart` picks the API base URL. `dev` uses `http://10.0.2.2:3000` on Android emulator and `http://localhost:3000` elsewhere.
- `API_BASE_URL=<url>` overrides the URL entirely (checked first in `ApiService.fromEnv()`).
- The same `ENVIRONMENT` define also selects Firebase options in `lib/firebase_options.dart` (separate dev/pprod/prod projects). For Android, `android/app/google-services.json` must match — CI copies `google-services-{pprod,prod}.json` over it before building.

## Architecture

Layered, with barrel files at every level (`core/core.dart`, `services/services.dart`, `models/models.dart`, `screens/screens.dart`, `widgets/widgets.dart`, …). Import via the barrels; add new files to the relevant barrel.

- `lib/core/` — no UI.
  - `services/api_service.dart` — singleton (`ApiService.fromEnv()`), a single large HTTP client holding nearly every backend call (auth, members, gyms, subscriptions, plannings, check-in, admins). It is the most-connected node in the codebase; most screens depend on it plus `AuthService`. Smaller feature services (`banner_service`, `store_service`) wrap `ApiService` for their domain.
  - `auth_service.dart` — session/token persistence (`flutter_secure_storage`) and biometric login (`local_auth`).
  - `fcm_service.dart` (Firebase push, registers device token with backend), `notification_service.dart` (local/scheduled notifications), `app_version_service.dart` (version check on every platform against the server's latest `version_code`; update goes through the Play Store on Android, a message elsewhere — no in-app APK download), `locale_service.dart`.
  - `theme/` — `AppColors`, `AppTextStyles`, `AppTheme` (light/dark), `ThemeProvider` (persisted in SharedPreferences).
  - `l10n/app_localizations.dart` — hand-written translation map (fr / en / ar with RTL), **not** generated from ARB. Add a key to all three language maps and a getter.
- `lib/screens/{auth,admin,member,common}/` — screens by role. `SplashScreen` is the entry and routes to admin or member home based on the logged-in user's role.
- `lib/widgets/` — `common/` (design-system components: `ModernButton`, `ModernCard`, `ModernTextField`, `StatusBadge`, `BannerCarousel`), `responsive/` (`ResponsiveLayout`, `ResponsiveGrid`, `ResponsiveCard`), `platform/` (desktop and watch variants). Breakpoints and device detection live in `core/utils/platform_utils.dart`.

State management is plain `ChangeNotifier` + `InheritedWidget` scopes (`ThemeProviderScope`, `LocaleServiceScope` in `main.dart`) — no Provider/Riverpod/Bloc. `main.dart` also initializes Firebase, notifications, FCM, global error reporting, and calls the native `team.fitness.security` MethodChannel to block screenshots (Android `FLAG_SECURE` in `MainActivity.kt`, iOS in `AppDelegate.swift`).

## Release flow

Versioning is fully automated by semantic-release (`.releaserc.json`, `.github/workflows/semantic-release.yml`) — do not hand-edit the version in `pubspec.yaml` or `version-metadata.json`.

- Commits must follow Conventional Commits (`feat:` → minor, `fix:`/`perf:`/`refactor:` → patch, `!`/BREAKING → major; `docs/chore/style/test/ci/build` → no release).
- Push to `staging` → `x.y.z-beta.N` prerelease built with `ENVIRONMENT=pprod`; push to `main` → production release built with `ENVIRONMENT=prod`.
- `scripts/update-version-metadata.js` rewrites `pubspec.yaml` and `version-metadata.json` during release; the single build-and-deploy job then signs the AAB, uploads it via Fastlane (`android/fastlane`), and publishes the version metadata to `POST /android/update-version` — the only source of the server's `version.json`, which the in-app version check reads. No APK is built or distributed outside the Play Store.
- PRs into `main`/`staging` run `pr-validation.yml`: analyze (`--fatal-infos`), test, debug APK build. CI pins Flutter 3.35.7 and Java 17.
