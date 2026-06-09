import 'package:flutter/material.dart';
import '../core/utils/responsive.dart';

/// Adaptive scaffold that switches between bottom nav (mobile) and side rail (desktop)
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onNavigationChanged;
  final List<NavigationItem> items;
  final Widget? floatingActionButton;
  final String title;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.items,
    this.floatingActionButton,
    this.title = 'AttendanceAI',
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isMobile(context)) {
      // Mobile: Bottom Navigation
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          elevation: 0,
        ),
        body: body,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onNavigationChanged,
          type: BottomNavigationBarType.fixed,
          items: items
              .map((item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: item.label,
                  ))
              .toList(),
        ),
        floatingActionButton: floatingActionButton,
      );
    } else {
      // Desktop/Tablet: Side Navigation Rail
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: onNavigationChanged,
              labelType: Responsive.isDesktop(context)
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.selected,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.face, size: 32, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 8),
                    if (Responsive.isDesktop(context))
                      Text(
                        'AttendanceAI',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                  ],
                ),
              ),
              destinations: items
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.icon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Column(
                children: [
                  // Top bar for desktop
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Spacer(),
                        // Add search, notifications, profile here
                      ],
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }
  }
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.label,
  });
}
