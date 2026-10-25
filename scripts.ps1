# Flutter Team Oustad App - PowerShell Scripts
# Usage: .\scripts.ps1 <command> [options]

param(
    [Parameter(Position=0)]
    [string]$Command,
    
    [Parameter()]
    [string]$Url
)

function Show-Help {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         Flutter Team Oustad App - PowerShell Scripts                 ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🌍 Environments:" -ForegroundColor Yellow
    Write-Host "   • dev (default)  → http://localhost:3000 or http://10.0.2.2:3000" -ForegroundColor White
    Write-Host "   • pprod          → https://api-pprod.team-oustad.com" -ForegroundColor White
    Write-Host "   • prod           → https://api.team-oustad.com" -ForegroundColor White
    Write-Host ""
    Write-Host "📱 Run Commands (Development):" -ForegroundColor Cyan
    Write-Host "  install            - Install all dependencies (flutter pub get)" -ForegroundColor Green
    Write-Host "  run                - Run app in dev mode (auto-detect platform)" -ForegroundColor Green
    Write-Host "  run-android        - Run app on Android emulator (dev)" -ForegroundColor Green
    Write-Host "  run-windows        - Run app on Windows (dev)" -ForegroundColor Green
    Write-Host "  run-web            - Run app on Web (dev)" -ForegroundColor Green
    Write-Host "  run-ios            - Run app on iOS simulator (dev)" -ForegroundColor Green
    Write-Host ""
    Write-Host "🔶 Run Commands (Pre-Production):" -ForegroundColor Cyan
    Write-Host "  run-pprod          - Run app on pprod environment" -ForegroundColor Yellow
    Write-Host "  run-android-pprod  - Run Android app on pprod" -ForegroundColor Yellow
    Write-Host "  run-windows-pprod  - Run Windows app on pprod" -ForegroundColor Yellow
    Write-Host "  run-web-pprod      - Run Web app on pprod" -ForegroundColor Yellow
    Write-Host "  run-ios-pprod      - Run iOS app on pprod" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔴 Run Commands (Production):" -ForegroundColor Cyan
    Write-Host "  run-prod           - Run app on prod environment" -ForegroundColor Red
    Write-Host "  run-android-prod   - Run Android app on prod" -ForegroundColor Red
    Write-Host "  run-windows-prod   - Run Windows app on prod" -ForegroundColor Red
    Write-Host "  run-web-prod       - Run Web app on prod" -ForegroundColor Red
    Write-Host "  run-ios-prod       - Run iOS app on prod" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Options:" -ForegroundColor Cyan
    Write-Host "  -Url <url>         - Override API URL (e.g., -Url http://192.168.1.100:3000)" -ForegroundColor Yellow
    Write-Host "                       Example: .\scripts.ps1 run-windows -Url http://192.168.1.50:3000" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🛠️ Device Management:" -ForegroundColor Cyan
    Write-Host "  emulators          - List available emulators" -ForegroundColor Green
    Write-Host "  launch             - Launch Pixel 9 Pro emulator" -ForegroundColor Green
    Write-Host "  devices            - Show connected devices" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 Build Commands:" -ForegroundColor Cyan
    Write-Host "  build-apk          - Build APK for dev (debug)" -ForegroundColor Green
    Write-Host "  build-apk-pprod    - Build APK for pprod" -ForegroundColor Yellow
    Write-Host "  build-apk-prod     - Build APK for prod" -ForegroundColor Red
    Write-Host "  build-appbundle-pprod - Build App Bundle for pprod" -ForegroundColor Yellow
    Write-Host "  build-appbundle-prod  - Build App Bundle for prod" -ForegroundColor Red
    Write-Host "  build-windows-pprod   - Build Windows exe for pprod" -ForegroundColor Yellow
    Write-Host "  build-windows-prod    - Build Windows exe for prod" -ForegroundColor Red
    Write-Host "  build-web-pprod       - Build Web for pprod" -ForegroundColor Yellow
    Write-Host "  build-web-prod        - Build Web for prod" -ForegroundColor Red
    Write-Host ""
    Write-Host "🧹 Maintenance:" -ForegroundColor Cyan
    Write-Host "  clean              - Clean build files" -ForegroundColor Green
    Write-Host "  analyze            - Analyze code for issues" -ForegroundColor Green
    Write-Host "  format             - Format all Dart files" -ForegroundColor Green
    Write-Host "  test               - Run all tests" -ForegroundColor Green
    Write-Host "  upgrade            - Upgrade all dependencies" -ForegroundColor Green
    Write-Host "  doctor             - Check Flutter installation" -ForegroundColor Green
    Write-Host ""
    Write-Host "🏋  Borne d'accueil (kiosk):" -ForegroundColor Cyan
    Write-Host "  kiosk-setup        - Création du tunnel Cloudflare (une seule fois)" -ForegroundColor Magenta
    Write-Host "  kiosk-build        - Rebuild Flutter Web + lancer borne + tunnel" -ForegroundColor Magenta
    Write-Host "  kiosk              - Lancer borne (build existant) + tunnel" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "💡 Quick Examples:" -ForegroundColor Yellow
    Write-Host "   .\scripts.ps1 run-windows           # Dev with localhost" -ForegroundColor Gray
    Write-Host "   .\scripts.ps1 run-windows-pprod     # Pre-prod environment" -ForegroundColor Gray
    Write-Host "   .\scripts.ps1 build-apk-prod        # Production APK" -ForegroundColor Gray
    Write-Host "   .\scripts.ps1 run-windows -Url http://192.168.1.100:3000  # Custom URL" -ForegroundColor Gray
    Write-Host ""
}

switch ($Command) {
    "install" {
        Write-Host "Installing dependencies..." -ForegroundColor Cyan
        flutter pub get
    }
    "run" {
        Write-Host "Running app..." -ForegroundColor Cyan
        $cmd = "flutter run"
        if ($Url) {
            $cmd += " --dart-define=API_BASE_URL=$Url"
            Write-Host "Using API URL: $Url" -ForegroundColor Yellow
        }
        Write-Host "Command: $cmd" -ForegroundColor Gray
        Invoke-Expression $cmd
    }
    "run-android" {
        Write-Host "Running app on Android emulator..." -ForegroundColor Cyan
        $cmd = "flutter run -d emulator-5554"
        if ($Url) {
            $cmd += " --dart-define=API_BASE_URL=$Url"
            Write-Host "Using API URL: $Url" -ForegroundColor Yellow
        }
        Write-Host "Command: $cmd" -ForegroundColor Gray
        Invoke-Expression $cmd
    }
    "run-windows" {
        Write-Host "Running app on Windows..." -ForegroundColor Cyan
        if ($Url) {
            Write-Host "Using custom API URL: $Url" -ForegroundColor Yellow
        } else {
            Write-Host "Using default API URL: http://localhost:3000" -ForegroundColor Green
        }
        $cmd = "flutter run -d windows"
        if ($Url) {
            $cmd += " --dart-define=API_BASE_URL=$Url"
        }
        Write-Host "Command: $cmd" -ForegroundColor Gray
        Invoke-Expression $cmd
    }
    "run-web" {
        Write-Host "Running app on Web..." -ForegroundColor Cyan
        if ($Url) {
            Write-Host "Using custom API URL: $Url" -ForegroundColor Yellow
        } else {
            Write-Host "Using default API URL: http://localhost:3000" -ForegroundColor Green
        }
        $cmd = "flutter run -d chrome"
        if ($Url) {
            $cmd += " --dart-define=API_BASE_URL=$Url"
        }
        Write-Host "Command: $cmd" -ForegroundColor Gray
        Invoke-Expression $cmd
    }
    "run-ios" {
        Write-Host "Running app on iOS Simulator..." -ForegroundColor Cyan
        if ($Url) {
            Write-Host "Using custom API URL: $Url" -ForegroundColor Yellow
        } else {
            Write-Host "Using default API URL: http://localhost:3000" -ForegroundColor Green
        }
        $cmd = "flutter run -d ios"
        if ($Url) {
            $cmd += " --dart-define=API_BASE_URL=$Url"
        }
        Write-Host "Command: $cmd" -ForegroundColor Gray
        Invoke-Expression $cmd
    }
    "emulators" {
        Write-Host "Available emulators:" -ForegroundColor Cyan
        flutter emulators
    }
    "launch" {
        Write-Host "Launching Pixel 9 Pro emulator..." -ForegroundColor Cyan
        flutter emulators --launch Pixel_9_Pro
    }
    "devices" {
        Write-Host "Connected devices:" -ForegroundColor Cyan
        flutter devices
    }
    "clean" {
        Write-Host "Cleaning build files..." -ForegroundColor Cyan
        flutter clean
        Write-Host "Done! Run 'install' command to reinstall dependencies." -ForegroundColor Green
    }
    "build-apk" {
        Write-Host "Building APK for release..." -ForegroundColor Cyan
        $cmd = "flutter build apk --release"
        if ($Url) {
            $cmd += " --dart-define=API_BASE_URL=$Url"
            Write-Host "Using API URL: $Url" -ForegroundColor Yellow
        }
        Write-Host "Command: $cmd" -ForegroundColor Gray
        Invoke-Expression $cmd
        Write-Host "APK built at: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    }
    "build-apk-debug" {
        Write-Host "Building debug APK for testing..." -ForegroundColor Cyan
        $cmd = "flutter build apk --debug"
        if ($Url) {
            $cmd += " --dart-define=API_BASE_URL=$Url"
            Write-Host "Using API URL: $Url" -ForegroundColor Yellow
        }
        Write-Host "Command: $cmd" -ForegroundColor Gray
        Invoke-Expression $cmd
        Write-Host "Debug APK built at: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Green
    }
    # Pre-Production Run Commands
    "run-pprod" {
        Write-Host "Running app on PPROD environment..." -ForegroundColor Yellow
        Write-Host "API URL: https://api-pprod.team-oustad.com" -ForegroundColor Yellow
        flutter run --dart-define=ENVIRONMENT=pprod
    }
    "run-android-pprod" {
        Write-Host "Running Android app on PPROD environment..." -ForegroundColor Yellow
        Write-Host "API URL: https://api-pprod.team-oustad.com" -ForegroundColor Yellow
        flutter run -d emulator-5554 --dart-define=ENVIRONMENT=pprod
    }
    "run-windows-pprod" {
        Write-Host "Running Windows app on PPROD environment..." -ForegroundColor Yellow
        Write-Host "API URL: https://api-pprod.team-oustad.com" -ForegroundColor Yellow
        flutter run -d windows --dart-define=ENVIRONMENT=pprod
    }
    "run-web-pprod" {
        Write-Host "Running Web app on PPROD environment..." -ForegroundColor Yellow
        Write-Host "API URL: https://api-pprod.team-oustad.com" -ForegroundColor Yellow
        flutter run -d chrome --dart-define=ENVIRONMENT=pprod
    }
    "run-ios-pprod" {
        Write-Host "Running iOS app on PPROD environment..." -ForegroundColor Yellow
        Write-Host "API URL: https://api-pprod.team-oustad.com" -ForegroundColor Yellow
        flutter run -d ios --dart-define=ENVIRONMENT=pprod
    }
    
    # Production Run Commands
    "run-prod" {
        Write-Host "⚠️  Running app on PRODUCTION environment ⚠️" -ForegroundColor Red
        Write-Host "API URL: https://api.team-oustad.com" -ForegroundColor Red
        flutter run --dart-define=ENVIRONMENT=prod
    }
    "run-android-prod" {
        Write-Host "⚠️  Running Android app on PRODUCTION environment ⚠️" -ForegroundColor Red
        Write-Host "API URL: https://api.team-oustad.com" -ForegroundColor Red
        flutter run -d emulator-5554 --dart-define=ENVIRONMENT=prod
    }
    "run-windows-prod" {
        Write-Host "⚠️  Running Windows app on PRODUCTION environment ⚠️" -ForegroundColor Red
        Write-Host "API URL: https://api.team-oustad.com" -ForegroundColor Red
        flutter run -d windows --dart-define=ENVIRONMENT=prod
    }
    "run-web-prod" {
        Write-Host "⚠️  Running Web app on PRODUCTION environment ⚠️" -ForegroundColor Red
        Write-Host "API URL: https://api.team-oustad.com" -ForegroundColor Red
        flutter run -d chrome --dart-define=ENVIRONMENT=prod
    }
    "run-ios-prod" {
        Write-Host "⚠️  Running iOS app on PRODUCTION environment ⚠️" -ForegroundColor Red
        Write-Host "API URL: https://api.team-oustad.com" -ForegroundColor Red
        flutter run -d ios --dart-define=ENVIRONMENT=prod
    }
    
    # Build Commands - Pre-Production
    "build-apk-pprod" {
        Write-Host "Building APK for PPROD environment..." -ForegroundColor Yellow
        Write-Host "API URL: https://api-pprod.team-oustad.com" -ForegroundColor Yellow
        flutter build apk --release --dart-define=ENVIRONMENT=pprod
        Write-Host "PPROD APK built at: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    }
    "build-appbundle-pprod" {
        Write-Host "Building App Bundle for PPROD environment..." -ForegroundColor Yellow
        Write-Host "API URL: https://api-pprod.team-oustad.com" -ForegroundColor Yellow
        flutter build appbundle --release --dart-define=ENVIRONMENT=pprod
        Write-Host "PPROD App Bundle built at: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
    }
    "build-windows-pprod" {
        Write-Host "Building Windows executable for PPROD environment..." -ForegroundColor Yellow
        Write-Host "API URL: https://api-pprod.team-oustad.com" -ForegroundColor Yellow
        flutter build windows --release --dart-define=ENVIRONMENT=pprod
        Write-Host "PPROD Windows build completed at: build\windows\x64\runner\Release\" -ForegroundColor Green
    }
    "build-web-pprod" {
        Write-Host "Building Web application for PPROD environment..." -ForegroundColor Yellow
        Write-Host "API URL: https://api-pprod.team-oustad.com" -ForegroundColor Yellow
        flutter build web --release --dart-define=ENVIRONMENT=pprod
        Write-Host "PPROD Web build completed at: build\web\" -ForegroundColor Green
    }
    
    # Build Commands - Production
    "build-apk-prod" {
        Write-Host "⚠️  Building APK for PRODUCTION environment ⚠️" -ForegroundColor Red
        Write-Host "API URL: https://api.team-oustad.com" -ForegroundColor Red
        flutter build apk --release --dart-define=ENVIRONMENT=prod
        Write-Host "PRODUCTION APK built at: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    }
    "build-appbundle-prod" {
        Write-Host "⚠️  Building App Bundle for PRODUCTION environment ⚠️" -ForegroundColor Red
        Write-Host "API URL: https://api.team-oustad.com" -ForegroundColor Red
        flutter build appbundle --release --dart-define=ENVIRONMENT=prod
        Write-Host "PRODUCTION App Bundle built at: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
    }
    "build-windows-prod" {
        Write-Host "⚠️  Building Windows executable for PRODUCTION environment ⚠️" -ForegroundColor Red
        Write-Host "API URL: https://api.team-oustad.com" -ForegroundColor Red
        flutter build windows --release --dart-define=ENVIRONMENT=prod
        Write-Host "PRODUCTION Windows build completed at: build\windows\x64\runner\Release\" -ForegroundColor Green
    }
    "build-web-prod" {
        Write-Host "⚠️  Building Web application for PRODUCTION environment ⚠️" -ForegroundColor Red
        Write-Host "API URL: https://api.team-oustad.com" -ForegroundColor Red
        flutter build web --release --dart-define=ENVIRONMENT=prod
        Write-Host "PRODUCTION Web build completed at: build\web\" -ForegroundColor Green
    }
    
    "build-appbundle" {
        Write-Host "Building App Bundle for Play Store..." -ForegroundColor Cyan
        flutter build appbundle --release
        Write-Host "App Bundle built at: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
    }
    "build-windows" {
        Write-Host "Building Windows executable..." -ForegroundColor Cyan
        $cmd = "flutter build windows --release"
        if ($Url) {
            $cmd += " --dart-define=API_BASE_URL=$Url"
            Write-Host "Using API URL: $Url" -ForegroundColor Yellow
        } else {
            Write-Host "Using default API URL: http://localhost:3000" -ForegroundColor Green
        }
        Write-Host "Command: $cmd" -ForegroundColor Gray
        Invoke-Expression $cmd
        Write-Host "Windows build completed at: build\windows\x64\runner\Release\" -ForegroundColor Green
    }
    "build-web" {
        Write-Host "Building Web application..." -ForegroundColor Cyan
        $cmd = "flutter build web --release"
        if ($Url) {
            $cmd += " --dart-define=API_BASE_URL=$Url"
            Write-Host "Using API URL: $Url" -ForegroundColor Yellow
        } else {
            Write-Host "Using default API URL: http://localhost:3000" -ForegroundColor Green
        }
        Write-Host "Command: $cmd" -ForegroundColor Gray
        Invoke-Expression $cmd
        Write-Host "Web build completed at: build\web\" -ForegroundColor Green
    }
    "analyze" {
        Write-Host "Analyzing code..." -ForegroundColor Cyan
        flutter analyze
    }
    "format" {
        Write-Host "Formatting Dart files..." -ForegroundColor Cyan
        dart format .
    }
    "test" {
        Write-Host "Running tests..." -ForegroundColor Cyan
        flutter test
    }
    "upgrade" {
        Write-Host "Upgrading dependencies..." -ForegroundColor Cyan
        flutter pub upgrade
    }
    "doctor" {
        Write-Host "Checking Flutter installation..." -ForegroundColor Cyan
        flutter doctor -v
    }
    "kiosk" {
        & "$PSScriptRoot\scripts\start-kiosk.ps1"
    }
    "kiosk-build" {
        & "$PSScriptRoot\scripts\start-kiosk.ps1" -Build
    }
    "kiosk-setup" {
        & "$PSScriptRoot\scripts\start-kiosk.ps1" -Setup
    }
    default {
        if ($Command) {
            Write-Host "Unknown command: $Command" -ForegroundColor Red
            Write-Host ""
        }
        Show-Help
    }
}
