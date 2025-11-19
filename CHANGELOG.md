# 📋 Changelog

All notable changes to Team Fitness App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [1.0.0-beta.12](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.11...v1.0.0-beta.12) (2025-11-19)


### 🐛 Bug Fixes

* **ci:** use git reset --hard to ensure latest version is used for build ([955d806](https://github.com/TeamFitness/mobile-app/commit/955d806d03bd54f9043cd3ea3712830592d87439))

## [1.0.0-beta.11](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.10...v1.0.0-beta.11) (2025-11-16)


### 🐛 Bug Fixes

* correct ENVIRONMENT variable reference in semantic-release config ([d7acaae](https://github.com/TeamFitness/mobile-app/commit/d7acaae45411a8b31c38fe327aca07d3561cb25c))

## [1.0.0-beta.10](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.9...v1.0.0-beta.10) (2025-11-16)


### 🐛 Bug Fixes

* build APK after version update in semantic-release ([a2d63b9](https://github.com/TeamFitness/mobile-app/commit/a2d63b9e1a4ebedb768eb454e296340ea8123b2b))

## [1.0.0-beta.9](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.8...v1.0.0-beta.9) (2025-11-16)


### 🐛 Bug Fixes

* update version files before building APK ([c68f93e](https://github.com/TeamFitness/mobile-app/commit/c68f93eb4c0751a4726d145310639550bb2ab535))

## [1.0.0-beta.8](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.7...v1.0.0-beta.8) (2025-11-16)


### ✨ New Features

* improve OTA update dialog UX ([f1111fb](https://github.com/TeamFitness/mobile-app/commit/f1111fbdf223f3d510be0db3326209f927e159a8))

## [1.0.0-beta.7](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.6...v1.0.0-beta.7) (2025-11-16)


### ✨ New Features

* auto install updates ([804b3fd](https://github.com/TeamFitness/mobile-app/commit/804b3fd079d2bba632555aac416c6c1c23097449))
* improve OTA update UX and member QR code display ([cf01923](https://github.com/TeamFitness/mobile-app/commit/cf01923ef188c48c01fdb08551c9e0c9b36f7ede))

## [1.0.0-beta.6](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.5...v1.0.0-beta.6) (2025-11-16)


### 🐛 Bug Fixes

* **ci:** fix artifact download and OTA upload in semantic-release workflow ([243a062](https://github.com/TeamFitness/mobile-app/commit/243a062329e544bcee2b86d2f73f45a4191fb566))

## [1.0.0-beta.5](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.4...v1.0.0-beta.5) (2025-11-16)


### 🐛 Bug Fixes

* broken imports after project structure reorganization ([#5](https://github.com/TeamFitness/mobile-app/issues/5)) ([6da9fc5](https://github.com/TeamFitness/mobile-app/commit/6da9fc53d96ab030880fc99e564b23b9ccd1ad34))
* Consolidate URL configuration to eliminate redundant platform detection ([#6](https://github.com/TeamFitness/mobile-app/issues/6)) ([45f600f](https://github.com/TeamFitness/mobile-app/commit/45f600fccfc5db27b6ad763192cc77d1f758194f))
* correct import paths in responsive widgets after project restructure ([#7](https://github.com/TeamFitness/mobile-app/issues/7)) ([7ad375f](https://github.com/TeamFitness/mobile-app/commit/7ad375f77fee2cb11ccec01103a987f5fdf32670))


### ♻️ Code Refactoring

* reorganize project structure and clean up unnecessary files ([fe5fe15](https://github.com/TeamFitness/mobile-app/commit/fe5fe153a870adee01689bf5adc8cf2fac0ee10a))

## [1.0.0-beta.4](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.3...v1.0.0-beta.4) (2025-11-16)


### ✨ New Features

* Add environment-aware OTA update URL- OTA service now detects ENVIRONMENT and uses appropriate update check URL- pprod uses /check-update-beta endpoint- prod uses /check-update endpoint- dev uses localhost for testing ([eecc601](https://github.com/TeamFitness/mobile-app/commit/eecc6010ae8edbfdab0279635eb792ecd157d935))

## [1.0.0-beta.3](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.2...v1.0.0-beta.3) (2025-11-16)


### 🐛 Bug Fixes

* Correct environment configuration URLs ([ed8c57d](https://github.com/TeamFitness/mobile-app/commit/ed8c57d3028110c0a504a78047cecf57037d2997))

## [1.0.0-beta.2](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.1...v1.0.0-beta.2) (2025-11-16)


### 🐛 Bug Fixes

* clean changelog markdown links and upload version-metadata as artifact ([298967a](https://github.com/TeamFitness/mobile-app/commit/298967a9f9bc76e52474627c49681060ac6c1150))

## 1.0.0-beta.1 (2025-11-15)


### ✨ New Features

* configure semantic release with bearer token authentication for OTA deployment ([864d6f1](https://github.com/TeamFitness/mobile-app/commit/864d6f1ad44fe46f65ec5e6b2d0f62a597378d37))
* team app initial commit ([dd6d563](https://github.com/TeamFitness/mobile-app/commit/dd6d5638a0db2b9cd22a0b9ae99a09673707b6db)), closes [#1](https://github.com/TeamFitness/mobile-app/issues/1)


### 🐛 Bug Fixes

* capture prerelease versions in semantic-release workflow ([d567e57](https://github.com/TeamFitness/mobile-app/commit/d567e5760dd97ffcdb4a2ef7da42b6bcda5ace3b))
* correct Kotlin syntax in build.gradle.kts for applicationVariants ([adb1847](https://github.com/TeamFitness/mobile-app/commit/adb1847dc67c626bbe3b8efbac583cb81b57e799))
* improve version extraction regex in semantic-release workflow ([fee5cfa](https://github.com/TeamFitness/mobile-app/commit/fee5cfa050cd9b5927daa8dbfa1b9e0caf51210f))
* pass release notes via temp file to avoid shell syntax errors ([8a62408](https://github.com/TeamFitness/mobile-app/commit/8a6240815ebb33f7ad07b30e59d9b3abf117e59a))
* updated node version ([4e708a6](https://github.com/TeamFitness/mobile-app/commit/4e708a64707f29a7c579705574f369aad54f7c59))


### ♻️ Code Refactoring

* remove redundant Firebase config logic from Gradle (handled by CI/CD) ([78aa666](https://github.com/TeamFitness/mobile-app/commit/78aa666fb6e5b4074995452d64c5f7a2e4c38efe))

<!-- AUTOMATICALLY GENERATED BY SEMANTIC-RELEASE -->
