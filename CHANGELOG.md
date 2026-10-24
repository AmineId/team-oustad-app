# 📋 Changelog

All notable changes to Team Fitness App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [1.0.0-beta.103](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.102...v1.0.0-beta.103) (2026-10-24)


### 🐛 Bug Fixes

* **build:** remplacer afterEvaluate par run{} dans PluginHandler.kt ([64d5908](https://github.com/TeamFitness/mobile-app/commit/64d5908151cf56d131f2559fd6bf531bde766ad7))

## [1.0.0-beta.102](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.101...v1.0.0-beta.102) (2026-10-24)


### 🐛 Bug Fixes

* **build:** déclencher CI avec --stacktrace pour diagnostiquer afterEvaluate ([378c68e](https://github.com/TeamFitness/mobile-app/commit/378c68e24b00d2b46453d2d81c1a15de4b3c4fe7))

## [1.0.0-beta.101](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.100...v1.0.0-beta.101) (2026-10-24)


### 🐛 Bug Fixes

* **build:** restore .kt sources avant patch + logs détaillés avant/après ([107edcb](https://github.com/TeamFitness/mobile-app/commit/107edcb14e500458b9c229e0f0c33bbd7c09f2ac))

## [1.0.0-beta.100](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.99...v1.0.0-beta.100) (2026-10-24)


### 🐛 Bug Fixes

* **build:** early-return dans configurePluginProject si plugin déjà configuré ([36bab77](https://github.com/TeamFitness/mobile-app/commit/36bab7713c128aff360d45c45fd12b89cc6b0445))

## [1.0.0-beta.99](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.98...v1.0.0-beta.99) (2026-10-24)


### 🐛 Bug Fixes

* **build:** guard pluginProject.afterEvaluate déjà évalué ([6021a0a](https://github.com/TeamFitness/mobile-app/commit/6021a0a30e14d9aecddcc8c39d710dbe706738c9))

## [1.0.0-beta.98](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.97...v1.0.0-beta.98) (2026-10-24)


### 🐛 Bug Fixes

* **build:** patch aussi PluginHandler.kt pour l'extension flutter ([fe057aa](https://github.com/TeamFitness/mobile-app/commit/fe057aa790749ba23dd6dc6c5378f9e1071d69f0))

## [1.0.0-beta.97](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.96...v1.0.0-beta.97) (2026-10-24)


### ✨ New Features

* **showcase:** éditeur CMS vitrine + toggle watch sync ([4f10829](https://github.com/TeamFitness/mobile-app/commit/4f108293cc7676a744fa81846dba44fcf77d7cb1))

## [1.0.0-beta.96](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.95...v1.0.0-beta.96) (2026-10-24)


### ✨ New Features

* **theme:** palette Midnight Gold + 3 couleurs identité + widgets animés ([9c595d0](https://github.com/TeamFitness/mobile-app/commit/9c595d0ff1927cb1c09f62c666aa1dbf70b646c6)), closes [#E8961](https://github.com/TeamFitness/mobile-app/issues/E8961) [#10B981](https://github.com/TeamFitness/mobile-app/issues/10B981) [#8B5CF6](https://github.com/TeamFitness/mobile-app/issues/8B5CF6) [#07111](https://github.com/TeamFitness/mobile-app/issues/07111) [#0F1E30](https://github.com/TeamFitness/mobile-app/issues/0F1E30) [#172840](https://github.com/TeamFitness/mobile-app/issues/172840) [#EFF3F8](https://github.com/TeamFitness/mobile-app/issues/EFF3F8) [#F7](https://github.com/TeamFitness/mobile-app/issues/F7)

## [1.0.0-beta.95](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.94...v1.0.0-beta.95) (2026-10-24)


### 🐛 Bug Fixes

* **ios:** ajouter UIDeviceFamily = [4] dans le plist Watch avant install ([68f0da9](https://github.com/TeamFitness/mobile-app/commit/68f0da9e5f40991e727c38e57799cff1dbfc096b))

## [1.0.0-beta.94](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.93...v1.0.0-beta.94) (2026-10-24)


### 🐛 Bug Fixes

* **ios:** patcher aussi CFBundleIdentifier de la Watch app avant install ([9ca925e](https://github.com/TeamFitness/mobile-app/commit/9ca925e5f085c6f28580c50d830808d994e7b8ad))

## [1.0.0-beta.93](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.92...v1.0.0-beta.93) (2026-10-24)


### 🐛 Bug Fixes

* **ios:** patcher WKCompanionAppBundleIdentifier avant install xtool ([fa101b8](https://github.com/TeamFitness/mobile-app/commit/fa101b8c3ff7a89b735db9dfae8ca99639b11b52))

## [1.0.0-beta.92](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.91...v1.0.0-beta.92) (2026-10-24)


### 🐛 Bug Fixes

* **ios:** ajouter WKCompanionAppBundleIdentifier dans le plist Watch ([25c1250](https://github.com/TeamFitness/mobile-app/commit/25c1250199bf044c12d77129f54d6cc226029213))

## [1.0.0-beta.91](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.90...v1.0.0-beta.91) (2026-10-24)


### 🐛 Bug Fixes

* **build:** purger le cache Gradle compilé avant patch FlutterPlugin ([fc14ac8](https://github.com/TeamFitness/mobile-app/commit/fc14ac8b30a3754062b55fbdee263497c12e363c))

## [1.0.0-beta.90](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.89...v1.0.0-beta.90) (2026-10-24)


### 🐛 Bug Fixes

* **build:** étendre le patch FlutterPlugin (extension flutter + debug dump) ([8783f1d](https://github.com/TeamFitness/mobile-app/commit/8783f1df34b8b11982e2b4b41697f12057c609fd))

## [1.0.0-beta.89](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.88...v1.0.0-beta.89) (2026-10-24)


### 🐛 Bug Fixes

* **build:** corriger generateLockfiles Android et cycle Xcode watchOS ([694c717](https://github.com/TeamFitness/mobile-app/commit/694c717e0590e8ff70e43214be5298de01cc68ca))

## [1.0.0-beta.88](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.87...v1.0.0-beta.88) (2026-10-24)


### 🐛 Bug Fixes

* **build:** corriger afterEvaluate Android et WCSessionDelegate watchOS ([b2db27f](https://github.com/TeamFitness/mobile-app/commit/b2db27f6786f9f5b17e9cdded88fc3e7fc692463))

## [1.0.0-beta.87](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.86...v1.0.0-beta.87) (2026-10-24)


### 🐛 Bug Fixes

* **build:** corriger 3 erreurs CI (Android, iOS, Web) ([51dc954](https://github.com/TeamFitness/mobile-app/commit/51dc9540ed5d3f93817df77ca04393b218bbbbb0))

## [1.0.0-beta.86](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.85...v1.0.0-beta.86) (2026-10-24)


### ✨ New Features

* **ios:** push notifications + Firebase iOS setup ([aa9de08](https://github.com/TeamFitness/mobile-app/commit/aa9de083b300a0fd4e36792f58bff38e7fc449a3))
* **ios:** script Ruby pour ajouter le target watchOS en CI ([4db59ce](https://github.com/TeamFitness/mobile-app/commit/4db59ce17d8d34ac54b49b479943d9a8c3db015f))
* rename package to team.oustad.app + Apple Watch & Wear OS modules ([b8b9acd](https://github.com/TeamFitness/mobile-app/commit/b8b9acd42656e9beceb386bd0d3867939ad6e726)), closes [#7C3](https://github.com/TeamFitness/mobile-app/issues/7C3)
* **watch:** pré-charger le QR code sur la montre au chargement ([c4dda41](https://github.com/TeamFitness/mobile-app/commit/c4dda41afb958a1df1fc55b6157a6848e7ab11d9))
* **wear:** Android Wear OS module complet ([61c5181](https://github.com/TeamFitness/mobile-app/commit/61c51814c80992cf4564844f58781c249c98204c))


### 🐛 Bug Fixes

* **ci:** corriger l'accès aux secrets dans le workflow iOS réutilisable ([73b3263](https://github.com/TeamFitness/mobile-app/commit/73b32636924c2ae838b7710740c0c192af26fc49))
* **wear:** intégrer le module wear dans l'AAB téléphone via wearApp() ([7c0f6bd](https://github.com/TeamFitness/mobile-app/commit/7c0f6bdcffffe47128e7c6e356915ef6b3e4c449))

## [1.0.0-beta.85](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.84...v1.0.0-beta.85) (2026-10-21)


### 🐛 Bug Fixes

* **ci:** use kiosk app icon in AltStore source ([6416f09](https://github.com/TeamFitness/mobile-app/commit/6416f090242944764cd7d0b651ddb97d6f788c54))

## [1.0.0-beta.84](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.83...v1.0.0-beta.84) (2026-10-21)


### ✨ New Features

* **kiosk:** replace Sideloadly iOS guide with AltStore private source ([3440fae](https://github.com/TeamFitness/mobile-app/commit/3440fae5367e5126603fe4bce762d9a0e4214058))

## [1.0.0-beta.83](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.82...v1.0.0-beta.83) (2026-10-21)


### ✨ New Features

* **gyms:** category tiles, feature rows and testimonials on the showcase ([f6d0f4d](https://github.com/TeamFitness/mobile-app/commit/f6d0f4d689de23abcfd2db9268303058e94c29b0))


### 🐛 Bug Fixes

* don't pop a crash-report email for errors the UI already handled ([0722628](https://github.com/TeamFitness/mobile-app/commit/072262800814e2c73b8403aec6fbdd45bcdb77ea))

## [1.0.0-beta.82](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.81...v1.0.0-beta.82) (2026-10-21)


### ✨ New Features

* **gyms:** gym description + embedded map on the showcase detail page ([51483f1](https://github.com/TeamFitness/mobile-app/commit/51483f10b1d38fd3822cf25ceba1b77bc835b807))
* **kiosk:** add webcam scanning alongside the hardware QR scanner ([4e43072](https://github.com/TeamFitness/mobile-app/commit/4e43072493d35ed713bce83b3f65e2f850920c05))


### 🐛 Bug Fixes

* **gyms:** single-line wordmark, drop broken marquee rotation, shorter hero ([872f7cc](https://github.com/TeamFitness/mobile-app/commit/872f7cc7a2aca8c77e28436d450c2b0727c23421))
* **kiosk:** show the real logo in the header instead of a "TF" badge ([21e915a](https://github.com/TeamFitness/mobile-app/commit/21e915a540cc7ec829c02499c93448eec05be890))

## [1.0.0-beta.81](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.80...v1.0.0-beta.81) (2026-10-21)


### ✨ New Features

* **gyms:** layered TEAM/OUSTAD wordmark with Vlavour + Roboto Black ([d8375d7](https://github.com/TeamFitness/mobile-app/commit/d8375d7d0f0579df0057fd91df539da55a75747f))


### 📚 Documentation

* **ios:** fix portproxy setup commands and add relay diagnostics ([4cebf37](https://github.com/TeamFitness/mobile-app/commit/4cebf370a6c88053d995d0fb592126a0bd7187aa))

## [1.0.0-beta.80](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.79...v1.0.0-beta.80) (2026-10-21)


### ✨ New Features

* **gyms:** push the showcase further — Anton display font, marquee, parallax ([5b13436](https://github.com/TeamFitness/mobile-app/commit/5b1343614249ce775bca03bd32e1c90b716b87ca))
* **kiosk:** show the Sideloadly guide in-app instead of a repo path ([3474684](https://github.com/TeamFitness/mobile-app/commit/347468458ac2dcee9e1dc645d3d9acb3e95a9dc0))

## [1.0.0-beta.79](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.78...v1.0.0-beta.79) (2026-10-21)


### ✨ New Features

* **gyms:** redesign public showcase with bold dark/gold brand theme ([f9cb8ce](https://github.com/TeamFitness/mobile-app/commit/f9cb8ceb8e0452a66d2209d00292911e2a56a9ae))


### 📚 Documentation

* **ios:** replace WSL/xtool kiosk install step with Sideloadly guide ([cc2abb4](https://github.com/TeamFitness/mobile-app/commit/cc2abb44646264ecbfaae5f100cf833224979dbe))

## [1.0.0-beta.78](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.77...v1.0.0-beta.78) (2026-10-21)


### ✨ New Features

* **gyms:** page vitrine publique des salles (web build dédié) ([9d2c77e](https://github.com/TeamFitness/mobile-app/commit/9d2c77e6f31426fd6117093a718906adc554a722))

## [1.0.0-beta.77](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.76...v1.0.0-beta.77) (2026-10-21)


### ✨ New Features

* **kiosk:** dedicated login screen + KIOSK_MODE direct boot ([2e78f97](https://github.com/TeamFitness/mobile-app/commit/2e78f9757c4da214fbb0bd845eccba6cdafead18))
* **kiosk:** restrict kiosk login to admin/owner roles only ([0d27a1c](https://github.com/TeamFitness/mobile-app/commit/0d27a1cf678c8377f44c31d9415c2c4a680f60f9))


### 🐛 Bug Fixes

* **ci:** auto-publish Android internal testing release instead of leaving it as draft ([f649d23](https://github.com/TeamFitness/mobile-app/commit/f649d238caf53ed4923dfa02013e45c4e4ff6fd7))


### ♻️ Code Refactoring

* **kiosk:** use kIsWeb instead of a KIOSK_MODE dart-define ([cda0cc2](https://github.com/TeamFitness/mobile-app/commit/cda0cc2c816b1f1105555484b9ce6fa2cbff9268))

## [1.0.0-beta.76](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.75...v1.0.0-beta.76) (2026-10-21)


### ♻️ Code Refactoring

* **ci:** fold kiosk deploy into Release & Deploy, add standalone dispatch to each reusable workflow ([3b5407e](https://github.com/TeamFitness/mobile-app/commit/3b5407e2319ccca0171b325d28d5cea414d2a6d8))

## [1.0.0-beta.75](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.74...v1.0.0-beta.75) (2026-10-21)


### ✨ New Features

* add kiosk install doc with Play Store/IPA links, split CI into reusable workflows, rebrand to Team Oustad ([17c41f0](https://github.com/TeamFitness/mobile-app/commit/17c41f0a1c63d868f951ff733068074af26ff276))


### 🐛 Bug Fixes

* remove reserved GITHUB_TOKEN secret and fix stale released-tag detection ([ecc7751](https://github.com/TeamFitness/mobile-app/commit/ecc7751d1ecbdbb6512e4f06e9d7411dd176ceca)), closes [#98](https://github.com/TeamFitness/mobile-app/issues/98) [#96](https://github.com/TeamFitness/mobile-app/issues/96) [#97](https://github.com/TeamFitness/mobile-app/issues/97)

## [1.0.0-beta.74](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.73...v1.0.0-beta.74) (2026-10-21)


### ✨ New Features

* add borne d'accueil button in admin home + kiosk scripts.ps1 commands ([47a9375](https://github.com/TeamFitness/mobile-app/commit/47a9375a8c07ea39d7acb4965b3fb402dac966b4))
* add kiosk check-in terminal + Cloudflare Pages CI ([680bc77](https://github.com/TeamFitness/mobile-app/commit/680bc7771acb5cbd5303a539f3980c39cacdfcf3))

## [1.0.0-beta.73](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.72...v1.0.0-beta.73) (2026-10-19)


### 🐛 Bug Fixes

* use Team Oustad as the app title in Android recent apps ([09aa9a9](https://github.com/TeamFitness/mobile-app/commit/09aa9a9159e6138e5042f900fcedcc079978eaa5))
* use the environment API for version check and publishing ([cf8386f](https://github.com/TeamFitness/mobile-app/commit/cf8386f0ad33f661dc79b0ee3283c6cf2d0918b9))


### 📚 Documentation

* sync swagger with backend (POST /android/update-version) ([1222231](https://github.com/TeamFitness/mobile-app/commit/1222231107bc02c4b1287822f27e05701a9ab3ee))

## [1.0.0-beta.72](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.71...v1.0.0-beta.72) (2026-10-19)


### ♻️ Code Refactoring

* replace OTA updater with cross-platform version check ([80c92d8](https://github.com/TeamFitness/mobile-app/commit/80c92d896cfb115c1f7e5507aa579c7e5619f059))

## [1.0.0-beta.71](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.70...v1.0.0-beta.71) (2026-10-19)


### 🐛 Bug Fixes

* **ios:** guard secure layer setup before window is attached ([81f24e8](https://github.com/TeamFitness/mobile-app/commit/81f24e8042769296952f39ef58ece54f6bc7c7a3))


### ⚡ Performance Improvements

* **member:** show cached profile first on QR page ([32a5b23](https://github.com/TeamFitness/mobile-app/commit/32a5b23a63378bf9981496655dcadcc35998ff30))


### ♻️ Code Refactoring

* replace OTA updater with cross-platform version check ([772d5d3](https://github.com/TeamFitness/mobile-app/commit/772d5d3ff580a87c4c35a51923abfe91a4069f58))

## [1.0.0-beta.70](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.69...v1.0.0-beta.70) (2026-10-19)


### ✨ New Features

* **member:** block screenshots on training program and planning, offline QR fallback ([9571b33](https://github.com/TeamFitness/mobile-app/commit/9571b33ce6b6513bd12b7afade5fd29b017ea20f))
* rename launcher app name to Team Oustad ([8667d1d](https://github.com/TeamFitness/mobile-app/commit/8667d1d36982bee3e53733a8f1ba63011a2f8d36))

## [1.0.0-beta.69](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.68...v1.0.0-beta.69) (2026-10-19)


### ✨ New Features

* **whatsapp:** edit the sender display name and profile picture ([5cd4920](https://github.com/TeamFitness/mobile-app/commit/5cd492031c3992b5ca9aad1e6c7480d5a393209f))

## [1.0.0-beta.68](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.67...v1.0.0-beta.68) (2026-10-19)


### ✨ New Features

* **notifications:** open the matching tab on notification tap; keep FCM token in sync ([7a05556](https://github.com/TeamFitness/mobile-app/commit/7a055563a78503d2e18ba268afddc1032e5abc49))


### 🐛 Bug Fixes

* **whatsapp:** read pairing code from the new 'code' response field ([ff7b335](https://github.com/TeamFitness/mobile-app/commit/ff7b33568f4dc39697b48f975a0d5ede133b0669))

## [1.0.0-beta.67](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.66...v1.0.0-beta.67) (2026-10-19)


### 🐛 Bug Fixes

* **ui:** keep FABs above the glass tab bar; block taps through glass bars ([4fdb18f](https://github.com/TeamFitness/mobile-app/commit/4fdb18f568fa40d3577a9f669eee9e8bfb35ef44))

## [1.0.0-beta.66](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.65...v1.0.0-beta.66) (2026-10-18)


### 🐛 Bug Fixes

* **ios:** transparent progressive blur under the native tab bar ([fabffc5](https://github.com/TeamFitness/mobile-app/commit/fabffc5bc29b1a4165e87c073d7a3d4060a193a8))
* **theme:** readable text colors in light theme ([ef78882](https://github.com/TeamFitness/mobile-app/commit/ef7888295b8e1353954d6ff3b829a58f26e3e9f8))
* **ui:** content scrolls beneath glass bars; theme-aware text colors ([6f3a24c](https://github.com/TeamFitness/mobile-app/commit/6f3a24cf0fdfbb27cc17f0387cd547cea395e2e5))

## [1.0.0-beta.65](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.64...v1.0.0-beta.65) (2026-10-18)


### ✨ New Features

* **ui:** interactive edge swipe-back for tab sub-views ([8d361a3](https://github.com/TeamFitness/mobile-app/commit/8d361a307fabb214c33c0d34b748d5e3a724c46a))


### 🐛 Bug Fixes

* **ios:** smooth content fade under native tab bar, drop hard clip ([4292621](https://github.com/TeamFitness/mobile-app/commit/4292621550912a80b65a086cf4dd133107c9906d))

## [1.0.0-beta.64](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.63...v1.0.0-beta.64) (2026-10-18)


### 🐛 Bug Fixes

* **ui:** WhatsApp tabs scroll with the page, rounder native tab bar ([1a5c166](https://github.com/TeamFitness/mobile-app/commit/1a5c166541ad3090533f9a2034048600e7f42dc2))

## [1.0.0-beta.63](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.62...v1.0.0-beta.63) (2026-10-18)


### 🐛 Bug Fixes

* **ios:** native tab bar no longer stretches to half the screen ([5d248b4](https://github.com/TeamFitness/mobile-app/commit/5d248b4dad6ff7d0085e55a1fe4f38ee4459f0a9))

## [1.0.0-beta.62](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.61...v1.0.0-beta.62) (2026-10-18)


### ✨ New Features

* **ios:** native iOS 26 Liquid Glass tab bar via cupertino_native ([9d1c5e9](https://github.com/TeamFitness/mobile-app/commit/9d1c5e9d70585751363f3f7785e61753da7e2c94))
* **ui:** iOS 26 Liquid Glass floating tab bar and fading glass header ([a85348f](https://github.com/TeamFitness/mobile-app/commit/a85348f856c7840e55d278870812cf0d808f679f))
* **ui:** seamless glass bars tinted from theme background ([0fce5cd](https://github.com/TeamFitness/mobile-app/commit/0fce5cd7448b2abd9c524c67f68924423e2c4fd2))


### 🐛 Bug Fixes

* **icons:** enlarge iOS launcher icon — logo now fills ~80% of canvas ([b24868a](https://github.com/TeamFitness/mobile-app/commit/b24868a6d7fc242dee41a1d2fd284db2769304d2))
* **ui:** admin sub-screens seamless with glass shell on iOS ([d0a2147](https://github.com/TeamFitness/mobile-app/commit/d0a2147606724ea3dcd4e25fac038e7a159ecfb3))
* **ui:** glass AppBar and clear insets on pushed member/common screens ([480ce86](https://github.com/TeamFitness/mobile-app/commit/480ce8608aea10bc85f633ab008560afa627a6df))
* **ui:** glass AppBar on WhatsApp screen, SafeArea on profile, swipe-back ([300a358](https://github.com/TeamFitness/mobile-app/commit/300a358288b8fcb26ed5033c0854860629b68bc9))
* **ui:** lift FABs above glass bottom nav on iOS ([635d67c](https://github.com/TeamFitness/mobile-app/commit/635d67ca4dec6135004a92d3904c0c2c4ba5f7ea))
* **ui:** lift FABs above the floating glass tab bar ([f7cf71e](https://github.com/TeamFitness/mobile-app/commit/f7cf71e5349165e4158a0baef4cbca7afdfc3a4d))
* **ui:** member profile and planning pages clear glass bars on iOS ([a215048](https://github.com/TeamFitness/mobile-app/commit/a2150487fe6e1095c7ceaef51c7c0e982b314cbf))

## [1.0.0-beta.61](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.60...v1.0.0-beta.61) (2026-10-18)


### 🐛 Bug Fixes

* **ux:** predictive back, camera permissions, glass nav bg, icon size ([755be2b](https://github.com/TeamFitness/mobile-app/commit/755be2b04eb65f60769f3914be674acb9a4b9228))

## [1.0.0-beta.60](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.59...v1.0.0-beta.60) (2026-10-18)


### ✨ New Features

* **ui:** redesign admin, member and login screens with iOS glass navigation ([1eb53a6](https://github.com/TeamFitness/mobile-app/commit/1eb53a64750ea97267000e89cf0205121bab1b03))


### 🐛 Bug Fixes

* **auth:** clear stale Keychain/Keystore token on fresh install ([60a6c15](https://github.com/TeamFitness/mobile-app/commit/60a6c15b2fa824f698b2ad4623cf0a1f5e397ccd))

## [1.0.0-beta.59](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.58...v1.0.0-beta.59) (2026-10-18)


### 🐛 Bug Fixes

* **ios-install:** handle versioned artifact names (ios-ipa-<env>-<ver>) ([2b270d2](https://github.com/TeamFitness/mobile-app/commit/2b270d2610c1ae3613e9b3631137e52b7ce7dc1d))

## [1.0.0-beta.58](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.57...v1.0.0-beta.58) (2026-10-18)


### 🐛 Bug Fixes

* **ios-install:** find latest non-expired artifact across recent runs ([69a4c40](https://github.com/TeamFitness/mobile-app/commit/69a4c4096b3aa4c87d8924e62b2349e12c82c58e))

## [1.0.0-beta.57](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.56...v1.0.0-beta.57) (2026-10-18)


### 🐛 Bug Fixes

* **icons:** replace white launcher icon background with brand dark color ([#1a1f2e](https://github.com/TeamFitness/mobile-app/issues/1a1f2e)) on all platforms ([017611a](https://github.com/TeamFitness/mobile-app/commit/017611af78465b7efb88454fc19e12280dd0a4d4)), closes [#1a1f2](https://github.com/TeamFitness/mobile-app/issues/1a1f2) [#1a1f2](https://github.com/TeamFitness/mobile-app/issues/1a1f2)
* **ios:** force AppBar transparency for Liquid Glass effect ([6064635](https://github.com/TeamFitness/mobile-app/commit/6064635018885df12f04fd87ef3b63c5d203bbb9))

## [1.0.0-beta.56](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.55...v1.0.0-beta.56) (2026-10-18)


### ✨ New Features

* **whatsapp:** add pairing code alternative to QR scan ([a7c36f4](https://github.com/TeamFitness/mobile-app/commit/a7c36f4f7dbad37c6cd5f3d0eb8b6845cba2d01c))

## [1.0.0-beta.55](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.54...v1.0.0-beta.55) (2026-10-18)


### ✨ New Features

* **dashboard,ios:** live admin stats with cache, iOS swipe-back and Liquid Glass ([46b3527](https://github.com/TeamFitness/mobile-app/commit/46b352731bff8a5d16a8ab42b4e7f9d1e8cb5f08))

## [1.0.0-beta.54](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.53...v1.0.0-beta.54) (2026-10-18)


### 🐛 Bug Fixes

* **icons:** apply dark background to legacy launcher PNGs ([ddc0c91](https://github.com/TeamFitness/mobile-app/commit/ddc0c9118a46f7b1fedf427ce05423684af0928f)), closes [#1a1f2](https://github.com/TeamFitness/mobile-app/issues/1a1f2)

## [1.0.0-beta.53](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.52...v1.0.0-beta.53) (2026-10-18)


### ✨ New Features

* implement new swagger routes (gym image, exercise removal, subscription renew, WhatsApp) ([8a0a3f4](https://github.com/TeamFitness/mobile-app/commit/8a0a3f40f62695a877f1396b329c452fed589f06))


### 🐛 Bug Fixes

* **auth,icons,ota:** biometric logout fix, dark launcher icon, OTA url_launcher ([9c96f9d](https://github.com/TeamFitness/mobile-app/commit/9c96f9d880e9aaa8f8885a5ba80941864d824ade)), closes [#1a1f2](https://github.com/TeamFitness/mobile-app/issues/1a1f2)
* **auth:** preserve credentials on logout so biometric re-login works ([770bde8](https://github.com/TeamFitness/mobile-app/commit/770bde8b9fe08b3c107e3550f2560c5ce579ee80))
* **ci:** add curl timeout and continue-on-error to server version update step ([c6c94a2](https://github.com/TeamFitness/mobile-app/commit/c6c94a22693a914a02608b935e414d4fbfbf0691))

## [1.0.0-beta.53](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.52...v1.0.0-beta.53) (2026-10-18)


### ✨ New Features

* implement new swagger routes (gym image, exercise removal, subscription renew, WhatsApp) ([8a0a3f4](https://github.com/TeamFitness/mobile-app/commit/8a0a3f40f62695a877f1396b329c452fed589f06))


### 🐛 Bug Fixes

* **auth:** preserve credentials on logout so biometric re-login works ([770bde8](https://github.com/TeamFitness/mobile-app/commit/770bde8b9fe08b3c107e3550f2560c5ce579ee80))
* **ci:** add curl timeout and continue-on-error to server version update step ([c6c94a2](https://github.com/TeamFitness/mobile-app/commit/c6c94a22693a914a02608b935e414d4fbfbf0691))

## [1.0.0-beta.53](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.52...v1.0.0-beta.53) (2026-10-18)


### ✨ New Features

* implement new swagger routes (gym image, exercise removal, subscription renew, WhatsApp) ([8a0a3f4](https://github.com/TeamFitness/mobile-app/commit/8a0a3f40f62695a877f1396b329c452fed589f06))


### 🐛 Bug Fixes

* **auth:** preserve credentials on logout so biometric re-login works ([770bde8](https://github.com/TeamFitness/mobile-app/commit/770bde8b9fe08b3c107e3550f2560c5ce579ee80))
* **ci:** add curl timeout and continue-on-error to server version update step ([c6c94a2](https://github.com/TeamFitness/mobile-app/commit/c6c94a22693a914a02608b935e414d4fbfbf0691))

## [1.0.0-beta.53](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.52...v1.0.0-beta.53) (2026-10-18)


### ✨ New Features

* implement new swagger routes (gym image, exercise removal, subscription renew, WhatsApp) ([8a0a3f4](https://github.com/TeamFitness/mobile-app/commit/8a0a3f40f62695a877f1396b329c452fed589f06))


### 🐛 Bug Fixes

* **ci:** add curl timeout and continue-on-error to server version update step ([c6c94a2](https://github.com/TeamFitness/mobile-app/commit/c6c94a22693a914a02608b935e414d4fbfbf0691))

## [1.0.0-beta.52](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.51...v1.0.0-beta.52) (2026-10-18)


### 🐛 Bug Fixes

* **ci:** use bundler to install Fastlane and resolve missing multi_json dep ([415fe91](https://github.com/TeamFitness/mobile-app/commit/415fe9165af729ec5d88862dc9ca8e79d001846e))

## [1.0.0-beta.51](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.50...v1.0.0-beta.51) (2026-10-18)


### 🐛 Bug Fixes

* **auth:** préserve le consentement biométrique lors de la déconnexion ([e2aac37](https://github.com/TeamFitness/mobile-app/commit/e2aac375891a0fa159e23dd6c622fb5e0207d81d))

## [1.0.0-beta.50](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.49...v1.0.0-beta.50) (2026-10-18)


### 🐛 Bug Fixes

* **auth:** bouton biométrie visible sans déclencher la dialog de consentement ([d87d1f4](https://github.com/TeamFitness/mobile-app/commit/d87d1f4f360376ba2f77899d7dac5a10cab27607))

## [1.0.0-beta.49](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.48...v1.0.0-beta.49) (2026-10-18)


### 🐛 Bug Fixes

* **auth:** affiche le bouton biométrie sans attendre le consentement préalable ([53d7feb](https://github.com/TeamFitness/mobile-app/commit/53d7febfca129352b70e62d4bd30366688cfb1aa))

## [1.0.0-beta.48](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.47...v1.0.0-beta.48) (2026-10-18)


### ✨ New Features

* **ios:** auto-detect iTunes relay + --build mode in ios-install.sh ([3230acd](https://github.com/TeamFitness/mobile-app/commit/3230acd576f56383fb7c727ec2fafb383daefab1))


### 🐛 Bug Fixes

* **ios:** trigger Face ID immediately after biometry consent ([6af598f](https://github.com/TeamFitness/mobile-app/commit/6af598fe4ee98d157322552d22e1c03e9f575e8c))

## [1.0.0-beta.47](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.46...v1.0.0-beta.47) (2026-10-18)


### 🐛 Bug Fixes

* **membres:** corrige 6 bugs gestion membres côté client ([f271992](https://github.com/TeamFitness/mobile-app/commit/f2719924baaf89ae1d03bff7e8ac6edbb35281c2))

## [1.0.0-beta.46](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.45...v1.0.0-beta.46) (2026-10-18)


### 🐛 Bug Fixes

* **ios:** add NSFaceIDUsageDescription, replace task switcher text with logo ([b056c69](https://github.com/TeamFitness/mobile-app/commit/b056c69da8ee84a38e58a9d5920fff2fb8061967))

## [1.0.0-beta.45](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.44...v1.0.0-beta.45) (2026-10-18)


### 🐛 Bug Fixes

* **ios:** skip Firebase init when bundle ID mismatches xtool re-signing ([7312b80](https://github.com/TeamFitness/mobile-app/commit/7312b8056868fba8db9a24ae34d53ea4acb05ead))

## [1.0.0-beta.44](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.43...v1.0.0-beta.44) (2026-10-18)


### ✨ New Features

* complete UI/UX overhaul — theme-aware colors, design system, fonts ([e48d749](https://github.com/TeamFitness/mobile-app/commit/e48d74957bac42f22770d5da32ab279b813138bf))

## [1.0.0-beta.43](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.42...v1.0.0-beta.43) (2026-01-03)


### 🐛 Bug Fixes

* multiple fixes for both os ([3e66497](https://github.com/TeamFitness/mobile-app/commit/3e664977d702f358e3d2448b38309dafe2c1eca9))

## [1.0.0-beta.42](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.41...v1.0.0-beta.42) (2026-01-03)


### ✨ New Features

* web app compatibility ([c1e3dee](https://github.com/TeamFitness/mobile-app/commit/c1e3deef67986f8189d6223bc2e53446952bba04))

## [1.0.0-beta.41](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.40...v1.0.0-beta.41) (2026-01-03)


### ✨ New Features

* add required address field to admin and member creation ([be62cb8](https://github.com/TeamFitness/mobile-app/commit/be62cb88698220b33ad2734dc7ea067cd542ba36))

## [1.0.0-beta.40](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.39...v1.0.0-beta.40) (2026-01-03)


### 🐛 Bug Fixes

* multiple fixes and enhancement ([eab096f](https://github.com/TeamFitness/mobile-app/commit/eab096fa4a2b9f1c6bdd035c1a587a862ac70cd3))

## [1.0.0-beta.39](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.38...v1.0.0-beta.39) (2026-01-02)


### 🐛 Bug Fixes

* build failure & add missing phone and shouldSendSetupEmail parameters to createMember ([#17](https://github.com/TeamFitness/mobile-app/issues/17)) ([7615e6e](https://github.com/TeamFitness/mobile-app/commit/7615e6e039f82b4f70d2144a762fe50a8bbff332))

## [1.0.0-beta.38](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.37...v1.0.0-beta.38) (2026-01-02)


### 🐛 Bug Fixes

* **api:** standardize user creation with firstName/lastName format ([ac02669](https://github.com/TeamFitness/mobile-app/commit/ac0266951539b1698398986f7777733ed10be003))

## [1.0.0-beta.37](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.36...v1.0.0-beta.37) (2026-01-02)


### ✨ New Features

* **api:** add new member endpoints and QR code auto-caching ([6c4e32e](https://github.com/TeamFitness/mobile-app/commit/6c4e32e3d9598c72db24a42f6b31b89abb3d7049))

## [1.0.0-beta.36](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.35...v1.0.0-beta.36) (2026-01-01)


### 🐛 Bug Fixes

* fastlane update check causing CI deployment failure ([#16](https://github.com/TeamFitness/mobile-app/issues/16)) ([61d8c38](https://github.com/TeamFitness/mobile-app/commit/61d8c3884562199025715b5c5b8347c6572936ae))

## [1.0.0-beta.35](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.34...v1.0.0-beta.35) (2026-01-01)


### 🐛 Bug Fixes

* use absolute path for AAB in fastlane supply ([#15](https://github.com/TeamFitness/mobile-app/issues/15)) ([4c906d5](https://github.com/TeamFitness/mobile-app/commit/4c906d52dbc6673a0b6c45d4b2703efc52871fdc))

## [1.0.0-beta.34](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.33...v1.0.0-beta.34) (2026-01-01)


### 🐛 Bug Fixes

* correct fastlane supply execution directory for Play Store deployment ([f89340d](https://github.com/TeamFitness/mobile-app/commit/f89340dbd6dd9c52ed106822ec2fece3d455ec26))

## [1.0.0-beta.33](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.32...v1.0.0-beta.33) (2026-01-01)


### 🐛 Bug Fixes

* subscription quota display and data structure ([73ff01f](https://github.com/TeamFitness/mobile-app/commit/73ff01fa689eef25ab38f712db4f792f0f374b99))

## [1.0.0-beta.32](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.31...v1.0.0-beta.32) (2026-01-01)


### ✨ New Features

* added banner and store management ([36883d0](https://github.com/TeamFitness/mobile-app/commit/36883d0e086d558291632efa6374b278f385458e))

## [1.0.0-beta.31](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.30...v1.0.0-beta.31) (2025-12-31)


### ♻️ Code Refactoring

* consolidate workflow jobs to eliminate artifact usage ([f0ebd96](https://github.com/TeamFitness/mobile-app/commit/f0ebd96856321fb8e2fa0ca571ed11d370d56ba9))

## [1.0.0-beta.30](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.29...v1.0.0-beta.30) (2025-12-31)


### 🐛 Bug Fixes

* add required if-no-files-found parameter to upload-artifact@v4 ([#11](https://github.com/TeamFitness/mobile-app/issues/11)) ([d5dba4a](https://github.com/TeamFitness/mobile-app/commit/d5dba4ac6629e59f26b10af72be491618125940e))

## [1.0.0-beta.29](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.28...v1.0.0-beta.29) (2025-12-31)


### ✨ New Features

* apply consistent styling across admin/owner/member screens ([844a2fe](https://github.com/TeamFitness/mobile-app/commit/844a2fe23f9b4b66742ff563608325ab988ca3ad))

## [1.0.0-beta.28](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.27...v1.0.0-beta.28) (2025-11-23)


### 🐛 Bug Fixes

* uniformiser la largeur des sections dans l'app mobile ([e46d529](https://github.com/TeamFitness/mobile-app/commit/e46d5292dc2edfa67aeab9d468e6245299addb2a))

## [1.0.0-beta.27](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.26...v1.0.0-beta.27) (2025-11-22)


### ✨ New Features

* add multi-language support with locale switcher ([#10](https://github.com/TeamFitness/mobile-app/issues/10)) ([f60005c](https://github.com/TeamFitness/mobile-app/commit/f60005c2b457ab5b46b40603e528ea92c5da7761))

## [1.0.0-beta.26](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.25...v1.0.0-beta.26) (2025-11-21)


### 🐛 Bug Fixes

* utiliser release_status draft pour app en mode draft ([1eebd5d](https://github.com/TeamFitness/mobile-app/commit/1eebd5ddcd2003b23ced31fd089531168629b3a1))

## [1.0.0-beta.25](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.24...v1.0.0-beta.25) (2025-11-21)


### 🐛 Bug Fixes

* utiliser heredoc pour écrire le service account JSON et valider ([f419e4c](https://github.com/TeamFitness/mobile-app/commit/f419e4c45d2aed6d5465ae63d710e97e76026c7a))

## [1.0.0-beta.24](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.23...v1.0.0-beta.24) (2025-11-21)


### 🐛 Bug Fixes

* utiliser chemin absolu pour service account JSON dans Fastlane ([f1859e7](https://github.com/TeamFitness/mobile-app/commit/f1859e7bd2ea05006197a04285a0c377a3db63c8))

## [1.0.0-beta.23](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.22...v1.0.0-beta.23) (2025-11-21)


### 🐛 Bug Fixes

* créer dossier changelogs et exécuter OTA après Play Store ([2a17abc](https://github.com/TeamFitness/mobile-app/commit/2a17abcbe53735eb42b277805651c5afffe2d74a))

## [1.0.0-beta.22](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.21...v1.0.0-beta.22) (2025-11-21)


### 🐛 Bug Fixes

* utiliser URL Play Store dans version.json et corriger chemin keystore ([e41cd41](https://github.com/TeamFitness/mobile-app/commit/e41cd41eddcb6348aeef049cfbe054b7afe187b8))

## [1.0.0-beta.21](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.20...v1.0.0-beta.21) (2025-11-21)


### 🐛 Bug Fixes

* corriger le chemin du keystore dans le workflow CI ([a84db51](https://github.com/TeamFitness/mobile-app/commit/a84db518982a90ed35313523e8a4d0a90b3b2779))

## [1.0.0-beta.20](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.19...v1.0.0-beta.20) (2025-11-21)


### ✨ New Features

* rediriger vers Play Store via backend au lieu de télécharger APK ([8524dc0](https://github.com/TeamFitness/mobile-app/commit/8524dc06b02db09a4ad1e7b0f8e7ae307a15e8b3))

## [1.0.0-beta.19](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.18...v1.0.0-beta.19) (2025-11-21)


### ✨ New Features

* configuration complète déploiement automatique Play Store avec notes de version ([5edd30d](https://github.com/TeamFitness/mobile-app/commit/5edd30ded31ef5aac6bf0bd76ca40cd86b82d376))

## [1.0.0-beta.18](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.17...v1.0.0-beta.18) (2025-11-21)


### ✨ New Features

* multiples fixes and enhancements ([f76b77d](https://github.com/TeamFitness/mobile-app/commit/f76b77d06b8ca33d6ac2ab7ab0aa99bc5f939781))

## [1.0.0-beta.17](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.16...v1.0.0-beta.17) (2025-11-21)


### ✨ New Features

* multiple interface fixes and doc for Play Store deployment ([2bf579f](https://github.com/TeamFitness/mobile-app/commit/2bf579fd5d921707ef85dd1d3af5a65a664a9864))

## [1.0.0-beta.16](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.15...v1.0.0-beta.16) (2025-11-20)


### ✨ New Features

* implement dynamic theme system across all screens ([75a9596](https://github.com/TeamFitness/mobile-app/commit/75a9596b8e41f02deed9307a409b1c43d199b40e))

## [1.0.0-beta.15](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.14...v1.0.0-beta.15) (2025-11-20)


### ✨ New Features

* Add workout notifications settings and onboarding tracking ([0698225](https://github.com/TeamFitness/mobile-app/commit/0698225d852e8195fd2d7e065c340027829b11cb))

## [1.0.0-beta.14](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.13...v1.0.0-beta.14) (2025-11-19)


### 🐛 Bug Fixes

* Corriger tous les problèmes Flutter analyze (67→6 info) ([d2355dd](https://github.com/TeamFitness/mobile-app/commit/d2355dddc4a224bcf2d0af706dbaef4800705f26))

## [1.0.0-beta.13](https://github.com/TeamFitness/mobile-app/compare/v1.0.0-beta.12...v1.0.0-beta.13) (2025-11-19)

### 🎨 Added - Design System Moderne

#### Système de Thème
* Ajout du support mode clair/sombre avec basculement fluide
* Nouveau `ThemeProvider` avec sauvegarde des préférences utilisateur
* Palette de couleurs complète pour les deux thèmes
* Système de typographie standardisé (H1-H6, body, caption, etc.)

#### Nouveaux Composants UI
* `ModernButton` : Bouton standardisé avec 5 variantes (primary, secondary, text, danger, success)
* `ModernCard` : Card moderne avec bordures arrondies et ombres adaptatives
* `ModernTextField` : Input field cohérent avec le design system
* `StatusBadge` : Badge de statut avec 5 types (success, error, warning, info, primary)
* `ThemeToggleButton` : Bouton animé pour basculer entre thèmes

#### Structure de Thème
* `lib/core/theme/app_colors.dart` : Palette de couleurs complète
* `lib/core/theme/app_text_styles.dart` : Styles de texte standardisés
* `lib/core/theme/app_theme.dart` : Configuration des thèmes clair/sombre
* `lib/core/theme/theme_provider.dart` : Gestion du changement de thème
* `lib/core/theme/theme.dart` : Export centralisé

#### Mise à Jour des Écrans
* Ajout du bouton de changement de thème dans `AdminHomeScreen`
* Ajout du bouton de changement de thème dans `MemberHomeScreen`

#### Documentation
* `THEME_SYSTEM_GUIDE.md` : Guide complet d'utilisation du système de thème
* `DESIGN_SYSTEM_UPDATE.md` : Documentation des changements et nouveautés
* `test-design-system.ps1` : Script de test du nouveau design system

### 🐛 Bug Fixes

* **ci:** correct APK path in OTA deploy step ([dab992a](https://github.com/TeamFitness/mobile-app/commit/dab992a71a46430f68b88c88269328411fbd0306))

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
