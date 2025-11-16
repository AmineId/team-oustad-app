# Database Connection Fix

## Problem
The mobile app was showing a "no connection to the database" error screen. This was caused by incorrect API URL configuration for different environments and platforms.

## Solution

### 1. Centralized Configuration (`lib/core/config/app_config.dart`)
Created a centralized configuration system that:
- Supports multiple environments (dev, pprod, prod)
- Handles platform-specific URLs automatically
  - Android emulator: `http://10.0.2.2:3000` (to access host machine)
  - Other platforms: `http://localhost:3000`
- Provides clear environment mapping

### 2. Improved API Service (`lib/core/services/api_service.dart`)
Enhanced the API service with:
- Clear URL resolution priority:
  1. `API_BASE_URL` environment variable (if set)
  2. `ENVIRONMENT` variable mapped to AppConfig
- Better error handling and timeout management
- Connection testing capability
- Detailed logging for debugging

### 3. Connection Test Screen (`lib/screens/connection_test_screen.dart`)
Added a diagnostic screen that:
- Tests database connectivity on startup
- Shows clear success/failure status
- Displays the actual URL being used
- Shows environment configuration
- Allows manual retry of connection test

## Usage

### Development Environment
```bash
# Uses localhost (or 10.0.2.2 on Android emulator)
flutter run
```

### Pre-Production Environment
```bash
# Uses https://api-pprod.team-oustad.com
flutter run --dart-define=ENVIRONMENT=pprod
```

### Production Environment
```bash
# Uses https://api.team-oustad.com
flutter run --dart-define=ENVIRONMENT=prod
```

### Custom API URL
```bash
# Override with specific URL
flutter run --dart-define=API_BASE_URL=https://custom-api.example.com
```

## Configuration Priority

The system uses this priority order to determine the API base URL:

1. **API_BASE_URL** (if set) - Explicit override
2. **ENVIRONMENT** → AppConfig mapping - Environment-based configuration
   - `dev` → Platform-specific localhost
   - `pprod` → `https://api-pprod.team-oustad.com`
   - `prod` → `https://api.team-oustad.com`

## Testing

The app now includes a connection test screen that automatically:
1. Tests connectivity on startup
2. Shows the resolved API URL
3. Displays environment configuration
4. Provides manual retry option

If connection fails, the screen shows:
- The error message
- The URL being used
- Current environment configuration
- Instructions for changing environment

## Troubleshooting

### "Connection timeout" error
- Check if the API server is running
- Verify the URL is correct
- Check network connectivity
- For Android emulator, ensure `10.0.2.2` can reach host machine

### "Wrong environment URL" issue
- Check the `--dart-define=ENVIRONMENT=xxx` parameter
- Verify the environment value is correct (dev/pprod/prod)
- See the connection test screen for actual resolved URL

### Android emulator can't connect
- The app automatically uses `10.0.2.2` for Android emulator
- Ensure your development server is listening on `0.0.0.0:3000` (not just `localhost`)

## Related PRs

This fix builds upon:
- PR #5: Fixed broken imports and API configuration
- PR #6: Consolidated URL configuration to use environment variables

## Changes Summary

- ✅ Created `AppConfig` with environment-specific configurations
- ✅ Improved `ApiService` with better error handling
- ✅ Added connection testing and diagnostic screen
- ✅ Platform-specific URL handling for Android emulator
- ✅ Clear documentation and troubleshooting guide
