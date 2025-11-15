# mobile-app# Team Fitness App 🏋️

A Flutter application for gym management with comprehensive multi-platform support and responsive design.

## Features

- 🔐 **Biometric Authentication** - Fingerprint/Face ID login
- 🔑 **Password Authentication** - Secure password-based login
- 🎨 **Dark Theme** - Professional dark design with orange accents
- 💾 **Persistent Settings** - Remember user preferences
- 📱 **Multi-platform** - Android, iOS, Windows, macOS, Linux, Web, and Smartwatch support
- 📐 **Responsive Design** - Adaptive UI for all screen sizes (watch to desktop)
- 🖥️ **Desktop-Optimized** - Side navigation, multi-column layouts, enhanced UX
- ⌚ **Watch-Optimized** - Compact UI for smartwatch displays

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

### 🌐 Automatic API Configuration

The app automatically detects the platform and uses the correct API URL:
- **Desktop/Web**: `http://localhost:3000` (automatic)
- **Android Emulator**: `http://10.0.2.2:3000` (automatic)
- **Custom URL**: Use `-Url` parameter (see examples below)

See **[API_CONFIGURATION.md](./API_CONFIGURATION.md)** and **[GUIDE_RAPIDE_MULTI_PLATEFORME.md](./GUIDE_RAPIDE_MULTI_PLATEFORME.md)** for details.

### Quick Start (PowerShell Scripts)

```powershell
# Make script executable (first time only)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Install dependencies
.\scripts.ps1 install

# Run on Windows (uses localhost automatically)
.\scripts.ps1 run-windows

# Run on Web (uses localhost automatically)
.\scripts.ps1 run-web

# Run on Android Emulator (uses 10.0.2.2 automatically)
.\scripts.ps1 launch          # Launch emulator first
.\scripts.ps1 run-android     # Run app

# Use custom API URL if needed
.\scripts.ps1 run-windows -Url http://192.168.1.100:3000
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

## Responsive Design 🎨

The app automatically adapts to different screen sizes:
- **Desktop (>600px)**: Side navigation, multi-column layouts (3-4 columns)
- **Mobile (300-600px)**: Bottom navigation, 2-column layouts
- **Smartwatch (<300px)**: Compact single-column layouts

See [RESPONSIVE_DESIGN.md](./RESPONSIVE_DESIGN.md) for detailed documentation.

## Project Structure

```
team_fitness_app/
├── lib/
│   ├── main.dart                           # App entry point
│   ├── utils/
│   │   └── platform_utils.dart             # Platform detection
│   ├── widgets/
│   │   ├── responsive_layout.dart          # Responsive scaffold
│   │   ├── responsive_grid.dart            # Responsive grids
│   │   ├── responsive_card.dart            # Responsive components
│   │   ├── desktop_widgets.dart            # Desktop-optimized widgets
│   │   └── watch_widgets.dart              # Watch-optimized widgets
│   ├── screens/
│   │   ├── login_screen.dart               # Login with biometric auth
│   │   ├── admin_home_screen.dart          # Admin dashboard
│   │   ├── member_home_screen.dart         # Member dashboard
│   │   └── ...                             # Other screens
│   └── services/                           # API, auth, notifications
├── assets/
│   └── images/                             # App assets
├── android/                                # Android specific code
├── ios/                                    # iOS specific code
├── windows/                                # Windows specific code
├── macos/                                  # macOS specific code
├── linux/                                  # Linux specific code
├── web/                                    # Web specific code
├── test/                                   # Unit and widget tests
├── RESPONSIVE_DESIGN.md                    # Responsive design guide
├── IMPLEMENTATION_SUMMARY.md               # Technical implementation details
├── VISUAL_GUIDE.md                         # Visual layout examples
├── pubspec.yaml                            # Dependencies and assets
├── scripts.ps1                             # PowerShell helper scripts
├── Makefile                                # Make commands
└── README.md                               # This file
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
| `.\scripts.ps1 run-android` | Run on Android emulator (10.0.2.2 auto) |
| `.\scripts.ps1 run-windows` | Run on Windows (localhost auto) |
| `.\scripts.ps1 run-web` | Run on Web (localhost auto) |
| `.\scripts.ps1 run-ios` | Run on iOS Simulator (localhost auto) |
| `.\scripts.ps1 emulators` | List emulators |
| `.\scripts.ps1 launch` | Launch Pixel 9 Pro emulator |
| `.\scripts.ps1 devices` | Show connected devices |
| `.\scripts.ps1 clean` | Clean build files |
| `.\scripts.ps1 build-apk` | Build release APK |
| `.\scripts.ps1 build-appbundle` | Build App Bundle |
| `.\scripts.ps1 build-windows` | Build Windows executable |
| `.\scripts.ps1 build-web` | Build Web application |
| `.\scripts.ps1 analyze` | Analyze code |
| `.\scripts.ps1 format` | Format code |
| `.\scripts.ps1 test` | Run tests |
| `.\scripts.ps1 upgrade` | Upgrade dependencies |
| `.\scripts.ps1 doctor` | Check Flutter setup |

**All commands support `-Url` parameter** to override the default API URL:
```powershell
.\scripts.ps1 run-windows -Url http://192.168.1.100:3000
```

## VS Code Integration

### Run Configuration
Press `F5` or click "Run > Start Debugging" to run the app.

### Recommended Extensions
- Flutter
- Dart
- Flutter Widget Snippets
- Awesome Flutter Snippets

## Documentation 📚

### Design & UI
- **[RESPONSIVE_DESIGN.md](./RESPONSIVE_DESIGN.md)** - Comprehensive guide to responsive design system
- **[IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md)** - Technical implementation details
- **[VISUAL_GUIDE.md](./VISUAL_GUIDE.md)** - Visual examples of layouts across platforms

### API & Configuration
- **[API_CONFIGURATION.md](./API_CONFIGURATION.md)** - Complete API URL configuration guide
- **[GUIDE_RAPIDE_MULTI_PLATEFORME.md](./GUIDE_RAPIDE_MULTI_PLATEFORME.md)** - Quick start guide (French)
- **[RESUME_CHANGEMENTS.md](./RESUME_CHANGEMENTS.md)** - Summary of recent changes (French)

## Next Steps

- [x] Multi-platform responsive design
- [x] Desktop optimization with side navigation
- [x] Smartwatch support with compact UI
- [ ] Backend API integration enhancements
- [ ] Advanced workout tracking features
- [ ] Progress charts and analytics
- [ ] Enhanced push notifications

## License

Private project - All rights reserved

## Support

For issues or questions, contact the development team.
