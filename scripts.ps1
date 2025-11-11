# Flutter Team Fitness App - PowerShell Scripts
# Usage: .\scripts.ps1 <command> [options]

param(
    [Parameter(Position=0)]
    [string]$Command
    # DB-related options removed: the app now talks to the backend API.
)

function Show-Help {
    Write-Host "Available commands:" -ForegroundColor Cyan
    Write-Host "  install            - Install all dependencies (flutter pub get)" -ForegroundColor Green
    Write-Host "  run                - Run app (connects to API configured in app)" -ForegroundColor Green
    Write-Host "  run-android        - Run app on Android emulator" -ForegroundColor Green
    Write-Host "  run-windows        - Run app on Windows" -ForegroundColor Green
    Write-Host "  emulators     - List available emulators" -ForegroundColor Green
    Write-Host "  launch        - Launch Pixel 9 Pro emulator" -ForegroundColor Green
    Write-Host "  devices       - Show connected devices" -ForegroundColor Green
    Write-Host "  clean         - Clean build files" -ForegroundColor Green
    Write-Host "  build-apk     - Build APK for release" -ForegroundColor Green
    Write-Host "  build-appbundle - Build App Bundle for Play Store" -ForegroundColor Green
    Write-Host "  analyze       - Analyze code for issues" -ForegroundColor Green
    Write-Host "  format        - Format all Dart files" -ForegroundColor Green
    Write-Host "  test          - Run all tests" -ForegroundColor Green
    Write-Host "  upgrade       - Upgrade all dependencies" -ForegroundColor Green
    Write-Host "  doctor        - Check Flutter installation" -ForegroundColor Green
    Write-Host "" -ForegroundColor White
}

switch ($Command) {
    "install" {
        Write-Host "Installing dependencies..." -ForegroundColor Cyan
        flutter pub get
    }
    "run" {
        Write-Host "Running app..." -ForegroundColor Cyan
        Write-Host "Command: flutter run" -ForegroundColor Gray
        Invoke-Expression "flutter run"
    }
    "run-android" {
        Write-Host "Running app on Android emulator..." -ForegroundColor Cyan
        Write-Host "Command: flutter run -d emulator-5554" -ForegroundColor Gray
        Invoke-Expression "flutter run -d emulator-5554"
    }
    "run-windows" {
        Write-Host "Running app on Windows..." -ForegroundColor Cyan
        Write-Host "Command: flutter run -d windows" -ForegroundColor Gray
        Invoke-Expression "flutter run -d windows"
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
        flutter build apk --release
        Write-Host "APK built at: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    }
    "build-appbundle" {
        Write-Host "Building App Bundle for Play Store..." -ForegroundColor Cyan
        flutter build appbundle --release
        Write-Host "App Bundle built at: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
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
    default {
        if ($Command) {
            Write-Host "Unknown command: $Command" -ForegroundColor Red
            Write-Host ""
        }
        Show-Help
    }
}
