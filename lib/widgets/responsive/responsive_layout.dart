import 'dart:io';
import 'package:flutter/material.dart';
import 'package:team_oustad_app/core/utils/platform_utils.dart';
import '../../core/theme/theme.dart';
import '../common/glass.dart';
import '../common/native_glass_tab_bar.dart';

/// A widget that builds different layouts based on device type
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? desktop;
  final Widget? watch;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.desktop,
    this.watch,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = PlatformUtils.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.watch:
        return watch ?? mobile;
      case DeviceType.desktop:
      case DeviceType.web:
        return desktop ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// A responsive scaffold that adapts navigation based on device type
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final List<NavigationItem> navigationItems;
  final int currentIndex;
  final Function(int) onNavigationChanged;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.navigationItems,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.body,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = PlatformUtils.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.watch:
        return _buildWatchLayout(context);
      case DeviceType.desktop:
      case DeviceType.web:
        return _buildDesktopLayout(context);
      case DeviceType.mobile:
        return _buildMobileLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isIOS = Platform.isIOS;

    final appBar = AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 0,
      backgroundColor: isIOS ? Colors.transparent : null,
      elevation: isIOS ? 0 : null,
      scrolledUnderElevation: isIOS ? 0 : null,
      forceMaterialTransparency: isIOS,
      title: Row(
        children: [
          ?leading,
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.appBarTheme.titleTextStyle?.color,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: actions,
      flexibleSpace: isIOS ? const GlassBar() : null,
    );

    final bottomNav = BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onNavigationChanged,
      type: BottomNavigationBarType.fixed,
      backgroundColor: isIOS
          ? Colors.transparent
          : theme.bottomNavigationBarTheme.backgroundColor,
      selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
      unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      elevation: isIOS ? 0 : 8,
      items: navigationItems
          .map((item) => BottomNavigationBarItem(
                icon: item.customWidget ?? Icon(item.icon),
                activeIcon: item.activeCustomWidget ??
                    item.customWidget ??
                    Icon(item.activeIcon ?? item.icon),
                label: item.label,
              ))
          .toList(),
    );

    // On iOS the body extends behind the glass AppBar and bottom nav.
    // Augment MediaQuery padding so scroll views push content clear of both.
    final effectiveBody = isIOS
        ? MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
                bottom: MediaQuery.of(context).padding.bottom + glassBottomReserved,
              ),
            ),
            child: body,
          )
        : body;

    return Scaffold(
      extendBodyBehindAppBar: isIOS,
      extendBody: isIOS,
      appBar: isIOS ? blockTapsThroughAppBar(appBar) : appBar,
      body: effectiveBody,
      bottomNavigationBar: isIOS ? blockTapsThrough(_buildIosTabBar()) : bottomNav,
    );
  }

  Widget _buildIosTabBar() {
    return supportsNativeLiquidGlass
          ? NativeGlassTabBar(
              currentIndex: currentIndex,
              onTap: onNavigationChanged,
              items: navigationItems
                  .map((i) => NativeTabItem(
                        label: i.label,
                        symbol: i.sfSymbol ?? 'circle',
                      ))
                  .toList(),
            )
          : GlassTabBar(
              currentIndex: currentIndex,
              onTap: onNavigationChanged,
              items: navigationItems
                  .map((item) => GlassTabItem(
                        icon: item.customWidget ?? Icon(item.icon),
                        activeIcon: item.activeCustomWidget ??
                            item.customWidget ??
                            Icon(item.activeIcon ?? item.icon),
                        label: item.label,
                      ))
                  .toList(),
            );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              border: Border(
                right: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo/Header
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24),
                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = navigationItems[index];
                      final isSelected = index == currentIndex;
                      return ListTile(
                        leading: Icon(
                          isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                          color: isSelected
                              ? context.palette.primary
                              : Colors.white60,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color:
                                isSelected ? context.palette.primary : Colors.white60,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                        onTap: () => onNavigationChanged(index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        ...?actions,
                      ],
                    ),
                  ),
                ),
                // Body
                Expanded(
                  child: Container(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchLayout(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: actions,
          ),
          SliverToBoxAdapter(child: body),
          // Bottom Navigation for watch (as list)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == currentIndex;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                      color: isSelected ? context.palette.primary : Colors.white60,
                      size: 16,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? context.palette.primary : Colors.white60,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => onNavigationChanged(index),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget? customWidget;
  final Widget? activeCustomWidget;
  final String? sfSymbol;

  const NavigationItem({
    required this.icon,
    this.sfSymbol,
    this.activeIcon,
    required this.label,
    this.customWidget,
    this.activeCustomWidget,
  });
}

