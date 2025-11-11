# mobile-app# Team Fitness App 🏋️

A Flutter mobile application for gym management with biometric authentication.

## Features

- 🔐 **Biometric Authentication** - Fingerprint/Face ID login
- 🔑 **Password Authentication** - Secure password-based login
- 🎨 **Dark Theme** - Professional dark design with orange accents
- 💾 **Persistent Settings** - Remember user preferences
- 📱 **Cross-platform** - Android, iOS, Windows support

## Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Android Emulator or physical device

## Installation

1. **Clone the repository**
   ```bash
   cd "I:\Dev Projects\team_fitness_app"
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Check Flutter installation**
   ```bash
   flutter doctor
   ```

## Running the App

### Quick Start (PowerShell Scripts)

```powershell
# Make script executable (first time only)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Install dependencies
.\scripts.ps1 install

# Launch emulator
.\scripts.ps1 launch

# Run app
.\scripts.ps1 run-android
```

### Using Make (if you have Make installed)

```bash
make install      # Install dependencies
make launch       # Launch emulator
make run-android  # Run on Android
```

### Direct Flutter Commands

#### List Available Emulators
```bash
flutter emulators
```

#### Launch Emulator
```bash
flutter emulators --launch Pixel_9_Pro
# or
flutter emulators --launch Medium_Phone_API_36.1
```

#### Check Connected Devices
```bash
flutter devices
```

#### Run on Android Emulator
```bash
flutter run -d emulator-5554
```

#### Run on Windows
```bash
flutter run -d windows
```

#### Run on Specific Device
```bash
flutter run -d <device-id>
```

## Development Commands

### Hot Reload
While the app is running, press `r` in the terminal to hot reload changes.

### Hot Restart
While the app is running, press `R` in the terminal to hot restart the app.

### Code Analysis
```bash
flutter analyze
```

### Format Code
```bash
dart format .
```

### Clean Build Files
```bash
flutter clean
flutter pub get
```

### Run Tests
```bash
flutter test
```

## Build Commands

### Build APK (Android)
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```
Output: `build\app\outputs\flutter-apk\app-release.apk`

### Build App Bundle (Google Play Store)
```bash
flutter build appbundle --release
```
Output: `build\app\outputs\bundle\release\app-release.aab`

### Build Windows Executable
```bash
flutter build windows --release
```
Output: `build\windows\runner\Release\team_fitness_app.exe`

## Project Structure

```
team_fitness_app/
├── lib/
│   ├── main.dart                    # App entry point with theme config
│   └── screens/
│       ├── login_screen.dart        # Login screen with biometric auth
│       └── home_screen.dart         # Home screen after login
├── assets/
│   └── images/
│       └── logo.png                 # App logo
├── android/                         # Android specific code
├── ios/                            # iOS specific code
├── windows/                        # Windows specific code
├── test/                           # Unit and widget tests
├── pubspec.yaml                    # Dependencies and assets
├── scripts.ps1                     # PowerShell helper scripts
├── Makefile                        # Make commands
└── README.md                       # This file
```

## Configuration

### Test Credentials
- **Password**: `password123`

### Theme Colors
- **Primary (Orange)**: `#e89547`
- **Background**: `#1a1f2e`
- **Surface**: `#2d3748`

### Dependencies
- `flutter` - Flutter SDK
- `local_auth: ^2.1.4` - Biometric authentication
- `shared_preferences: ^2.0.15` - Local storage

## Troubleshooting

### Emulator Not Showing
1. Check if emulator is running: `flutter devices`
2. Look for emulator window in taskbar (might be minimized)
3. Try Alt+Tab to switch to emulator window

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

### Gradle Issues (Android)
```bash
cd android
.\gradlew clean
cd ..
flutter run
```

### Connection Lost
If the app loses connection to the emulator:
1. Check if emulator is still running: `flutter devices`
2. Restart the app: `flutter run -d emulator-5554`

## Available Scripts (PowerShell)

| Command | Description |
|---------|-------------|
| `.\scripts.ps1 install` | Install dependencies |
| `.\scripts.ps1 run` | Run on default device |
| `.\scripts.ps1 run-android` | Run on Android emulator |
| `.\scripts.ps1 run-windows` | Run on Windows |
| `.\scripts.ps1 emulators` | List emulators |
| `.\scripts.ps1 launch` | Launch Pixel 9 Pro emulator |
| `.\scripts.ps1 devices` | Show connected devices |
| `.\scripts.ps1 clean` | Clean build files |
| `.\scripts.ps1 build-apk` | Build release APK |
| `.\scripts.ps1 build-appbundle` | Build App Bundle |
| `.\scripts.ps1 analyze` | Analyze code |
| `.\scripts.ps1 format` | Format code |
| `.\scripts.ps1 test` | Run tests |
| `.\scripts.ps1 upgrade` | Upgrade dependencies |
| `.\scripts.ps1 doctor` | Check Flutter setup |

## VS Code Integration

### Run Configuration
Press `F5` or click "Run > Start Debugging" to run the app.

### Recommended Extensions
- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets

## Next Steps

- [ ] Add more screens (profile, settings, workout tracking)
- [ ] Implement backend API integration
- [ ] Add database for local storage
- [ ] Implement workout plans feature
- [ ] Add progress tracking charts
- [ ] Enable push notifications

## License

Private project - All rights reserved

## Support

For issues or questions, contact the development team.
