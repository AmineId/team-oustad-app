# Project Context: Team Fitness App

This document provides a comprehensive overview of the Team Fitness App project, summarizing its purpose, technical stack, architecture, and current development practices. It is intended to serve as a central reference for maintaining context and ensuring precision in future interactions and development efforts.

## 1. Project Overview

**Purpose:** The Team Fitness App is a multi-platform Flutter application designed for gym management. It aims to provide comprehensive support for various platforms and offer a responsive user experience.

**Key Features:**
*   **Authentication:** Biometric (Fingerprint/Face ID) and password-based login.
*   **Theming:** Modern and minimalist design system with fluid light/dark mode switching.
*   **Multi-platform Support:** Android, iOS, Windows, macOS, Linux, Web, and Smartwatch.
*   **Responsive Design:** Adaptive UI for all screen sizes (from smartwatch to desktop).
*   **Gym Management:** Features for managing members, plannings, gyms, administrators, and subscriptions.
*   **Notifications:** Local notifications and Firebase Cloud Messaging (FCM) for push notifications.
*   **OTA Updates:** Over-the-air updates for the application.

## 2. Technical Stack

*   **Framework:** Flutter (version 3.9.2 or higher)
*   **Language:** Dart
*   **Dependencies (Key examples):**
    *   `local_auth`, `local_auth_android`, `local_auth_darwin`: Biometric authentication.
    *   `shared_preferences`: Local storage for user preferences.
    *   `flutter_secure_storage`: Secure storage for credentials.
    *   `url_launcher`: For launching URLs.
    *   `http`: HTTP client for API interactions.
    *   `flutter_local_notifications`, `timezone`: Local and scheduled notifications.
    *   `firebase_core`, `firebase_messaging`: Firebase integration for push notifications.
    *   `image_picker`: Image selection.
    *   `package_info_plus`: Application package information (for OTA updates).
    *   `path_provider`, `open_file`: File handling for OTA APK installation.
*   **Assets:** Stored in `assets/images/`.

## 3. Project Architecture

The application follows a layered and modular architecture, promoting separation of concerns, reusability, and maintainability.

### Core Principles:
*   **Layered Separation:**
    *   `Core`: Business logic and services.
    *   `Screens`: User interface (pages).
    *   `Widgets`: Reusable UI components.
*   **Module Separation:** Modules like `Admin`, `Auth`, `Member`, and `Common` encapsulate related functionalities.
*   **Type Separation:** `Responsive` and `Platform` specific widgets adapt the UI for different contexts.

### Directory Structure (`lib` folder):
*   `lib/main.dart`: Application entry point.
*   `lib/firebase_options.dart`: Firebase configuration.
*   `lib/core/`: Fundamental elements.
    *   `services/`: Application services (API, Auth, DB, FCM, Notifications, OTA Update).
    *   `config/`: Global application configuration.
    *   `utils/`: Utility functions (e.g., platform detection).
*   `lib/screens/`: User interface screens.
    *   `admin/`: Admin-specific screens.
    *   `auth/`: Authentication-related screens.
    *   `member/`: Member-specific screens.
    *   `common/`: Shared screens (Splash, Home, About, Settings, etc.).
*   `lib/widgets/`: Reusable UI components.
    *   `responsive/`: Responsive widgets (`responsive_layout.dart`, `responsive_grid.dart`, `responsive_card.dart`).
    *   `platform/`: Platform-specific widgets (`desktop_widgets.dart`, `watch_widgets.dart`).
    *   `common/`: Generic widgets.

### Data Flow & Dependencies:
*   **Flow:** User Action (Screen) → Widget Layer → Services (Core) → API/Database → Services (Core) → Widget Layer → Screen Update.
*   **Dependencies:** `Screens` → `Widgets` → `Core`. `Core` is independent. Circular dependencies are avoided.

## 4. Development Practices

### Coding Conventions:
*   **File Naming:**
    *   Screens: `*_screen.dart`
    *   Widgets: `*_widget.dart` or descriptive names.
    *   Services: `*_service.dart`
    *   Barrel files: `folder_name.dart`
*   **Class Naming:**
    *   Screens: `*Screen` or specific names.
    *   Widgets: `*Widget` or descriptive names.
    *   Services: `*Service`.
*   **Imports:** Encourages using barrel files (`package:team_fitness_app/core/core.dart`) rather than multiple direct imports.

### Version Control & Release:
*   **Conventional Commits:** Used for commit messages, adhering to a `<type>[optional scope]: <description>` format to enable automatic versioning and changelog generation.
    *   `feat`: Minor version bump.
    *   `fix`, `perf`, `refactor`: Patch version bump.
    *   `docs`, `style`, `test`, `chore`, `ci`, `build`: No version bump.
    *   `!` or `BREAKING CHANGE:` in footer triggers a Major version bump.
*   **Automatic Releases:** `semantic-release` automatically manages versions, changelogs, GitHub Releases, APK builds, and OTA deployments upon pushes to `main` or `staging`.
*   **Branch Strategy:**
    *   `main`: Production releases.
    *   `staging`: Beta releases.
    *   `feature/*`: Development branches.

### Build and Run:
*   **Commands:** Utilizes `flutter` commands directly, `Makefile` commands, and PowerShell scripts (`scripts.ps1`) for common operations like installing dependencies, running on various platforms, and building release artifacts.
*   **API Configuration:** Automatic platform detection for API URLs (`localhost` for desktop/web, `10.0.2.2` for Android emulator) with an option to specify a custom URL using `-Url` parameter.

### Documentation:
*   Extensive markdown documentation covers various aspects including API configuration, responsive design, implementation summaries, visual guides, and deployment procedures. These are now grouped in the `docs/` directory.
