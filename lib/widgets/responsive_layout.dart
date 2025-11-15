import 'package:flutter/material.dart';
import '../utils/platform_utils.dart';

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

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.navigationItems,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.body,
    this.actions,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onNavigationChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1a1f2e),
        selectedItemColor: const Color(0xFFe89547),
        unselectedItemColor: Colors.white60,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: navigationItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon ?? item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF1a1f2e),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Logo/Header
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        color: Color(0xFFe89547),
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Team Fitness',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                              ? const Color(0xFFe89547)
                              : Colors.white60,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color:
                                isSelected ? const Color(0xFFe89547) : Colors.white60,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: const Color(0xFFe89547).withOpacity(0.1),
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
                    color: const Color(0xFF1a1f2e),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
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
                        if (actions != null) ...actions!,
                      ],
                    ),
                  ),
                ),
                // Body
                Expanded(
                  child: Container(
                    color: const Color(0xFF1a1f2e),
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF1a1f2e),
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
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2d3748),
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
                      color: isSelected ? const Color(0xFFe89547) : Colors.white60,
                      size: 16,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFe89547) : Colors.white60,
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

  const NavigationItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}
