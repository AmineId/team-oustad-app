# Team Fitness Mobile App

Flutter mobile application for Team Fitness platform.

## Database Connection Fix

This PR fixes the persistent "no connection to database" error screen.

### Quick Start

```bash
# Development (localhost)
flutter run

# Pre-production
flutter run --dart-define=ENVIRONMENT=pprod

# Production  
flutter run --dart-define=ENVIRONMENT=prod
```

See [DATABASE_CONNECTION_FIX.md](DATABASE_CONNECTION_FIX.md) for detailed documentation.

## Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart       # Environment configuration
│   └── services/
│       └── api_service.dart      # API client with connection handling
├── screens/
│   └── connection_test_screen.dart  # Diagnostic screen
└── main.dart
```

## Environment Configuration

The app automatically resolves the API URL based on:
1. `API_BASE_URL` environment variable (highest priority)
2. `ENVIRONMENT` variable (dev/pprod/prod)
3. Platform detection (Android emulator uses 10.0.2.2)

## Features

- ✅ Automatic environment detection
- ✅ Platform-specific URL handling
- ✅ Connection testing and diagnostics
- ✅ Detailed error messages
- ✅ Timeout handling (30s for API calls, 10s for connection tests)

## Troubleshooting

If you see connection errors:
1. Check the connection test screen for the actual URL being used
2. Verify the backend server is running
3. For Android emulator, ensure backend listens on `0.0.0.0` not just `localhost`
4. Use `--dart-define=ENVIRONMENT=pprod` for pre-production testing