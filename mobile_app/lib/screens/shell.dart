import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/websocket_provider.dart';
import '../providers/notification_db_provider.dart';
import '../widgets/common/app_drawer.dart';
import 'home/home_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'students/students_screen.dart';
import 'cameras/cameras_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'notifications/notifications_screen.dart';
import 'notifications/notification_db_screen.dart';
import 'announcements/announcements_screen.dart';
import 'parent/parent_screen.dart';
import 'admin/admin_screen.dart';
import 'profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _lastSeenAlerts = 0;

  void _onTabSelected(int i) {
    setState(() {
      _index = i;
      // Mark WS alerts as read when viewing alerts tab
      final screens = _buildScreens(context.read<AuthProvider>());
      if (i < screens.length && screens[i].key == 'alerts') {
        _lastSeenAlerts = context.read<WebSocketProvider>().recentDetections.length;
      }
    });
  }

  List<_TabItem> _buildScreens(AuthProvider auth) {
    final items = <_TabItem>[
      _TabItem('home', 'Home', Icons.home_outlined, Icons.home, const HomeScreen()),
      _TabItem('dashboard', 'Dashboard', Icons.bar_chart_outlined, Icons.bar_chart, const DashboardScreen()),
    ];

    if (auth.isAdmin || auth.isTeacher) {
      items.add(_TabItem('cameras', 'Cameras', Icons.videocam_outlined, Icons.videocam, const CamerasScreen()));
      items.add(_TabItem('students', 'Students', Icons.people_outlined, Icons.people, const StudentsScreen()));
    }

    if (auth.isParent) {
      items.add(_TabItem('children', 'Children', Icons.family_restroom_outlined, Icons.family_restroom, const ParentScreen()));
    }

    items.add(_TabItem('announcements', 'News', Icons.campaign_outlined, Icons.campaign, const AnnouncementsScreen()));
    items.add(_TabItem('notifs', 'Inbox', Icons.inbox_outlined, Icons.inbox, const NotificationDbScreen()));
    items.add(_TabItem('alerts', 'Alerts', Icons.notifications_outlined, Icons.notifications, const NotificationsScreen()));

    if (auth.isAdmin || auth.isTeacher) {
      items.add(_TabItem('reports', 'Reports', Icons.description_outlined, Icons.description, const ReportsScreen()));
    }

    if (auth.isAdmin) {
      items.add(_TabItem('admin', 'Admin', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, const AdminScreen()));
    }

    if (auth.isAdmin || auth.isTeacher) {
      items.add(_TabItem('settings', 'Settings', Icons.settings_outlined, Icons.settings, const SettingsScreen()));
    }

    items.add(_TabItem('profile', 'Profile', Icons.person_outline, Icons.person, const ProfileScreen()));

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ws = context.watch<WebSocketProvider>();
    final screens = _buildScreens(auth);

    // Clamp index if screens changed
    if (_index >= screens.length) _index = 0;

    final unread = screens[_index].key != 'alerts'
        ? (ws.recentDetections.length - _lastSeenAlerts).clamp(0, 99)
        : 0;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      drawer: AppDrawer(currentIndex: _index, onSelect: (i) { setState(() => _index = i); Navigator.pop(context); }),
      body: screens[_index].screen,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.sidebarDark,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(screens.length, (i) {
                final item = screens[i];
                final active = _index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabSelected(i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(clipBehavior: Clip.none, children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary600 : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(active ? item.activeIcon : item.icon, color: active ? Colors.white : AppColors.gray400, size: 18),
                          ),
                          if (item.key == 'alerts' && unread > 0)
                            Positioned(
                              top: -4, right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              ),
                            ),
                          if (item.key == 'notifs')
                            Consumer<NotificationDbProvider>(
                              builder: (_, np, __) => np.unreadCount > 0
                                  ? Positioned(
                                      top: -4, right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(color: AppColors.primary600, shape: BoxShape.circle),
                                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                        child: Text('${np.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                        ]),
                        const SizedBox(height: 2),
                        Text(item.label, style: TextStyle(color: active ? Colors.white : AppColors.gray400, fontSize: 9, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String key, label;
  final IconData icon, activeIcon;
  final Widget screen;
  const _TabItem(this.key, this.label, this.icon, this.activeIcon, this.screen);
}
