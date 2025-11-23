# GEMINI.md

## Project Overview

This is a Flutter project for a gym management application called "Team Fitness App". It is a multi-platform application with a responsive design, supporting Android, iOS, Windows, macOS, Linux, Web, and even smartwatches.

The application features:
- Biometric and password authentication.
- A modern, minimalist design system with light and dark modes.
- Role-based access for admins and members.
- Push notifications using Firebase Cloud Messaging (FCM).
- Over-the-air (OTA) updates.

## Building and Running

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- An Android Emulator or a physical device

### Installation

1.  **Clone the repository**
    ```bash
    cd "I:\Dev Projects\team_fitness_app"
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

### Running the App

The project includes PowerShell scripts and a Makefile for easy execution of common tasks.

**Using PowerShell:**

```powershell
# Install dependencies
.\scripts.ps1 install

# Run on Windows
.\scripts.ps1 run-windows

# Run on Android Emulator
.\scripts.ps1 launch
.\scripts.ps1 run-android
```

**Using Make:**

```bash
make install
make launch
make run-android
```

**Direct Flutter Commands:**

```bash
# Run on a connected device
flutter run -d <device-id>
```

### Building the App

**Android:**

```bash
# Build a release APK
flutter build apk --release --dart-define=ENVIRONMENT=pprod

# Build an App Bundle for the Google Play Store
flutter build appbundle --release --dart-define=ENVIRONMENT=pprod
```

**Windows:**

```bash
flutter build windows --release
```

## Development Conventions

### Code Formatting

Use the following command to format the code:

```bash
dart format .
```

### Code Analysis

Use the following command to analyze the code for potential errors:

```bash
flutter analyze
```

### Testing

Run tests with the following command:

```bash
flutter test
```

### Architecture

The project follows a layered architecture with a clear separation of concerns:
-   **`core`**: Contains the core business logic, services, and configuration.
-   **`screens`**: Contains the UI for different modules of the application (admin, auth, member, common).
-   **`widgets`**: Contains reusable widgets, categorized into responsive, platform-specific, and common widgets.

The project uses barrel files to simplify imports.

### Contribution Guidelines

Please refer to the `CONTRIBUTING.md` file for contribution guidelines.
