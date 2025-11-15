# Responsive Design System

This document explains the responsive design system implemented for multi-platform support (Mobile, Desktop, Web, and Smartwatch).

## Overview

The Team Fitness app now supports multiple platforms with optimized UI/UX for each:

- **Mobile** (300px - 600px): Original bottom navigation, optimized for phone screens
- **Desktop** (>600px): Side navigation, multi-column layouts, enhanced spacing
- **Smartwatch** (<300px): Compact single-column layouts, simplified UI
- **Web**: Automatically adapts based on browser window size

## Platform Detection

### PlatformUtils

Located in `lib/utils/platform_utils.dart`, this utility class provides:

```dart
// Check platform type
PlatformUtils.isMobile  // Android or iOS
PlatformUtils.isDesktop // Windows, macOS, or Linux
PlatformUtils.isWeb     // Web browser

// Get device type based on screen size
PlatformUtils.getDeviceType(context)  // Returns DeviceType enum

// Screen size helpers
PlatformUtils.isLargeScreen(context)       // >= 600px
PlatformUtils.isExtraLargeScreen(context)  // >= 1200px

// Responsive dimensions
PlatformUtils.getResponsivePadding(context)
PlatformUtils.getFontSizeMultiplier(context)
PlatformUtils.getIconSize(context)
```

## Responsive Widgets

### ResponsiveScaffold

Automatically adapts navigation style based on device type:

```dart
ResponsiveScaffold(
  title: 'Dashboard',
  navigationItems: [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    // ... more items
  ],
  currentIndex: _currentIndex,
  onNavigationChanged: (index) {
    setState(() => _currentIndex = index);
  },
  body: _pages[_currentIndex],
)
```

**Behavior:**
- Mobile: Bottom navigation bar
- Desktop: Side navigation drawer
- Watch: Compact list navigation at bottom

### ResponsiveLayout

Build different layouts for different device types:

```dart
ResponsiveLayout(
  mobile: MobileWidget(),
  desktop: DesktopWidget(),  // Optional, defaults to mobile
  watch: WatchWidget(),      // Optional, defaults to mobile
)
```

### ResponsiveGrid

Automatically adjusts column count based on screen size:

```dart
ResponsiveGrid(
  spacing: 16.0,
  runSpacing: 16.0,
  children: [
    StatCard(...),
    StatCard(...),
    StatCard(...),
  ],
)
```

**Column counts:**
- Watch: 1 column
- Mobile: 2 columns
- Desktop: 3 columns
- Extra large desktop: 4 columns

### ResponsiveCard

Adapts card styling based on device:

```dart
ResponsiveCard(
  child: YourContent(),
)
```

### ResponsiveButton

Button that adapts size and padding:

```dart
ResponsiveButton(
  text: 'Submit',
  icon: Icons.check,
  onPressed: () {},
  isLoading: _isLoading,
)
```

## Platform-Specific Widgets

### Desktop Widgets

Located in `lib/widgets/desktop_widgets.dart`:

- **DesktopStatCard**: Enhanced stat cards with shadows and trends
- **DesktopActionCard**: Large action cards with icons and descriptions
- **DesktopDataTable**: Styled data tables for desktop
- **DesktopSearchBar**: Search bar with filter button

### Watch Widgets

Located in `lib/widgets/watch_widgets.dart`:

- **WatchStatCard**: Compact horizontal stat display
- **WatchActionButton**: Simplified action button
- **WatchListItem**: Small list item for limited space
- **WatchHeader**: Compact header section

## Implementation Guide

### Converting Existing Screens

1. **Update imports:**
```dart
import '../widgets/responsive_layout.dart';
```

2. **Replace Scaffold with ResponsiveScaffold:**
```dart
// Before
Scaffold(
  appBar: AppBar(title: Text('Title')),
  body: body,
  bottomNavigationBar: BottomNavigationBar(...),
)

// After
ResponsiveScaffold(
  title: 'Title',
  navigationItems: [...],
  currentIndex: _currentIndex,
  onNavigationChanged: (index) { ... },
  body: body,
)
```

3. **Add responsive layouts:**
```dart
// Use LayoutBuilder for inline responsiveness
LayoutBuilder(
  builder: (context, constraints) {
    final isDesktop = constraints.maxWidth > 600;
    final isWatch = constraints.maxWidth < 300;
    
    return Column(
      children: [
        Text(
          'Title',
          style: TextStyle(
            fontSize: isWatch ? 14 : (isDesktop ? 24 : 20),
          ),
        ),
        // ... more widgets
      ],
    );
  },
)
```

### Creating New Responsive Screens

1. Use `ResponsiveScaffold` for navigation
2. Use `LayoutBuilder` or `ResponsiveLayout` for content
3. Use platform-specific widgets when needed
4. Test on different screen sizes

## Best Practices

1. **Always consider all platforms** when adding new features
2. **Use responsive widgets** instead of hard-coded sizes
3. **Test on multiple screen sizes** (watch, mobile, tablet, desktop)
4. **Keep watch UI simple** - only essential information
5. **Leverage desktop space** - use multi-column layouts
6. **Maintain consistency** - use the theme colors and styles

## Theme Colors

- Primary: `#e89547` (Orange/Gold)
- Background: `#1a1f2e` (Dark Navy)
- Surface: `#2d3748` (Lighter Navy)
- Text: White with varying opacity

## Testing

To test different screen sizes:

1. **Flutter DevTools**: Use the device frame selector
2. **Browser**: Resize window for web version
3. **Physical devices**: Test on actual devices when possible

### Test Breakpoints

- Watch: 280px width
- Mobile Portrait: 375px width
- Mobile Landscape: 667px width
- Tablet: 768px width
- Desktop: 1200px width
- Large Desktop: 1920px width

## Future Enhancements

- [ ] Tablet-specific layouts (600px - 1200px)
- [ ] Landscape mode optimizations
- [ ] Custom themes for each platform
- [ ] Advanced desktop features (keyboard shortcuts, multi-window)
- [ ] Watch complications and widgets
