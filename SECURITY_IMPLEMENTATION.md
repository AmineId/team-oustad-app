# Screenshot and Screen Recording Prevention Implementation

## Overview
This document describes the security implementation to prevent screenshots and screen recording in the Team Fitness App.

## Implementation Details

### Android Implementation

**File Modified**: `android/app/src/main/kotlin/team/fitness/team_fitness_app/MainActivity.kt`

**Changes**:
- Added `FLAG_SECURE` to the application window in the `onCreate()` method
- This flag prevents screenshots and screen recordings at the OS level

**Code**:
```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // Prevent screenshots and screen recording
    window.setFlags(
        WindowManager.LayoutParams.FLAG_SECURE,
        WindowManager.LayoutParams.FLAG_SECURE
    )
}
```

**Behavior**:
- Screenshots will result in a black screen
- Screen recordings will show a black screen
- System screenshot notification will still appear, but the image will be blank
- Works on all Android versions

### iOS Implementation

**File Modified**: `ios/Runner/AppDelegate.swift`

**Changes**:
1. Added screenshot detection using `UIApplication.userDidTakeScreenshotNotification`
2. Added blur effect when app goes to background to protect content in app switcher
3. Automatically removes blur when app becomes active

**Code Features**:
```swift
// Screenshot detection
NotificationCenter.default.addObserver(
  self,
  selector: #selector(screenshotTaken),
  name: UIApplication.userDidTakeScreenshotNotification,
  object: nil
)

// Blur effect for app switcher
override func applicationWillResignActive(_ application: UIApplication) {
    addBlurEffect()
}
```

**Behavior**:
- Logs when a screenshot is taken (cannot prevent on iOS)
- Blurs content when user presses home button or switches apps
- Prevents sensitive information from appearing in the app switcher
- Automatically restores content when user returns to the app

## Verification Steps

### Android Verification
1. Build and install the app on an Android device or emulator
2. Navigate to any screen with sensitive information
3. Attempt to take a screenshot using:
   - Power + Volume Down buttons
   - Screenshot gesture (if available)
   - Screen recording (swipe down and tap record)
4. **Expected Result**: Screenshot/recording will show a black screen

### iOS Verification
1. Build and install the app on an iOS device or simulator
2. Navigate to any screen with sensitive information
3. Test screenshot detection:
   - Take a screenshot (Power + Volume Up)
   - Check console logs for "⚠️ Screenshot detected" message
4. Test app switcher protection:
   - Press home button or swipe up (on devices without home button)
   - View app switcher
   - **Expected Result**: App preview should show blurred content

## Security Considerations

### Android
- ✅ **Completely prevents** screenshots and screen recordings
- ✅ Works at the OS level
- ✅ No way to bypass without root access
- ⚠️ Does not prevent:
  - External cameras recording the screen
  - Screenshots taken on rooted devices with special apps

### iOS
- ⚠️ **Cannot prevent** screenshots (iOS limitation)
- ✅ Detects when screenshots are taken
- ✅ Protects content in app switcher
- ✅ Provides maximum available protection on iOS
- ⚠️ Does not prevent:
  - External cameras recording the screen
  - Screenshots (iOS doesn't allow apps to block them)

## Best Practices

1. **User Communication**: Consider informing users that the app is protected against screenshots
2. **Audit Logging**: The iOS screenshot detection can be extended to log events to a backend
3. **Alternative Protection**: For highly sensitive data, consider additional measures like:
   - Time-limited display of sensitive information
   - Requiring authentication before showing sensitive data
   - Using overlays that can't be captured

## Troubleshooting

### Android
- If FLAG_SECURE is not working, verify the app is running on a physical device (not all emulators support this)
- Check Android version compatibility (should work on all versions)

### iOS
- If blur effect doesn't appear, check that the app delegate methods are being called
- Verify in Xcode console that the observer is registered successfully
- Test on a physical device as simulator behavior may differ

## References

- [Android FLAG_SECURE Documentation](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#FLAG_SECURE)
- [iOS Screenshot Detection](https://developer.apple.com/documentation/uikit/uiapplication/1622966-userdidtakescreenshotnotificatio)
- [UIVisualEffectView Documentation](https://developer.apple.com/documentation/uikit/uivisualeffectview)

## Maintenance

This implementation requires no additional maintenance or configuration. The security features are automatically enabled when the app launches and will work on all supported iOS and Android versions.

## Questions or Issues

If you encounter any issues with the screenshot prevention features, please check:
1. Build configuration is correct
2. App has necessary permissions
3. Testing on appropriate devices (some features don't work in emulators)
