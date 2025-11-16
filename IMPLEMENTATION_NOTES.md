# Implementation Notes

## Context

This PR addresses the issue: "j'ai toujours un ecran pas de connexion à la db" (I always have a screen showing no database connection).

## Problem Analysis

Based on previous PRs (#5, #6) and the problem statement, the issue was:
1. The mobile app was consistently showing a database/API connection error
2. Environment configuration was not properly set up
3. Platform-specific URLs (Android emulator) were not handled correctly

## Solution Architecture

### 1. Configuration Layer (`AppConfig`)
- **Purpose**: Single source of truth for environment configuration
- **Environments**: dev, pprod, prod
- **Platform Intelligence**: Automatically detects Android emulator and uses 10.0.2.2 instead of localhost

### 2. Service Layer (`ApiService`)
- **Purpose**: Centralized API communication with robust error handling
- **Features**:
  - Configurable base URL through environment variables
  - 30-second timeout for API calls
  - 10-second timeout for connection tests
  - Comprehensive error messages
  - Request/response logging for debugging

### 3. UI Layer (`ConnectionTestScreen`)
- **Purpose**: Diagnostic tool for troubleshooting connection issues
- **Features**:
  - Automatic connection test on startup
  - Visual status indicator (green checkmark / red error)
  - Display of actual URL being used
  - Current environment configuration
  - Manual retry capability

## Key Design Decisions

### Why Not Const for AppConfig.dev?
The `dev` environment needs to return different URLs based on the platform (Android emulator vs others), so it cannot be const. It's implemented as a getter that calls `_getPlatformDevUrl()`.

### URL Resolution Priority
1. `API_BASE_URL` environment variable - Allows complete override
2. `ENVIRONMENT` variable (dev/pprod/prod) - Standard environment selection
3. Default to 'dev' if nothing specified

This gives developers maximum flexibility while maintaining safety.

### Connection Test on Startup
The app immediately tests connectivity when launched, providing instant feedback about configuration issues. This helps developers and users quickly identify problems.

### Error Handling Strategy
- All API calls have timeouts to prevent indefinite hangs
- Errors are caught, logged, and rethrown with context
- Connection test returns boolean for simple success/failure
- UI shows user-friendly error messages with technical details

## Testing Recommendations

### Manual Testing
1. **Development Environment**
   ```bash
   flutter run
   # Should connect to localhost (or 10.0.2.2 on Android emulator)
   ```

2. **Pre-Production Environment**
   ```bash
   flutter run --dart-define=ENVIRONMENT=pprod
   # Should connect to api-pprod.team-oustad.com
   ```

3. **Production Environment**
   ```bash
   flutter run --dart-define=ENVIRONMENT=prod
   # Should connect to api.team-oustad.com
   ```

4. **Custom URL**
   ```bash
   flutter run --dart-define=API_BASE_URL=https://custom.example.com
   # Should connect to custom.example.com
   ```

### Android Emulator Specific
- Verify that the app uses `10.0.2.2` automatically
- Test that development backend running on host machine is accessible
- Ensure backend server listens on `0.0.0.0:3000` not just `localhost:3000`

### Connection Failure Scenarios
- Backend server not running → Should show clear timeout error
- Wrong URL → Should show connection refused or 404 error
- Network issues → Should show timeout after 30 seconds

## Integration with Existing Code

This implementation is designed to be integrated into the existing codebase at `staging` branch:

1. **Drop-in Replacement**: These files can replace or supplement existing configuration
2. **Backwards Compatible**: Maintains compatibility with existing environment variable usage
3. **Minimal Dependencies**: Only uses `http` package, which is likely already present

## Migration Path

If integrating into existing codebase:

1. Copy `lib/core/config/app_config.dart`
2. Update existing `ApiService` or replace with `lib/core/services/api_service.dart`
3. Update main.dart to use the new configuration
4. Optionally add the `ConnectionTestScreen` for diagnostics
5. Test each environment thoroughly

## Security Considerations

- ✅ No secrets or API keys in code
- ✅ All URLs configurable through environment variables
- ✅ Timeout protection against hanging connections
- ✅ Proper error handling without exposing sensitive information
- ✅ HTTPS used for production and pre-production

## Future Improvements

1. **Authentication**: Add JWT token management to ApiService
2. **Retry Logic**: Implement exponential backoff for failed requests
3. **Caching**: Add response caching for offline support
4. **Analytics**: Track connection failures and environment usage
5. **Health Checks**: Periodic background connection testing

## Related Issues

- Fixes: "j'ai toujours un ecran pas de connexion à la db"
- Related to PR #5: API configuration fixes
- Related to PR #6: Environment variable consolidation

## Breaking Changes

None - this is additive functionality that doesn't modify existing code.

## Deployment Notes

When deploying to different environments:
- **Development**: No special configuration needed
- **Pre-Production**: Build with `--dart-define=ENVIRONMENT=pprod`
- **Production**: Build with `--dart-define=ENVIRONMENT=prod`

Ensure backend servers are accessible from the app's network context.
