import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../core/utils/app_theme.dart';
import '../core/utils/responsive.dart';
import '../providers/auth_provider.dart';
import '../providers/websocket_provider.dart';
import '../providers/notification_db_provider.dart';
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
import 'messages/conversations_screen.dart';
import 'profile/profile_screen.dart';
import 'marks/my_marks_screen.dart';
import 'attendance/attendance_history_screen.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/common/offline_banner.dart';
import '../widgets/common/chatbot_widget.dart';
import 'dart:ui';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static List<TabItem> buildTabItems(AuthProvider auth) {
    final items = <TabItem>[
      TabItem('home', 'Home', Icons.home_outlined, Icons.home, const HomeScreen()),
      TabItem('dashboard', 'Dashboard', Icons.bar_chart_outlined, Icons.bar_chart, const DashboardScreen()),
    ];

    if (auth.isAdmin || auth.isTeacher) {
      items.add(TabItem('cameras', 'Cameras', Icons.videocam_outlined, Icons.videocam, const CamerasScreen()));
      items.add(TabItem('students', 'Students', Icons.people_outlined, Icons.people, const StudentsScreen()));
    }

    if (auth.isParent) {
      items.add(TabItem('children', 'Children', Icons.family_restroom_outlined, Icons.family_restroom, const ParentScreen()));
      items.add(TabItem('attendance', 'Attendance', Icons.calendar_today_outlined, Icons.calendar_today, const AttendanceHistoryScreen()));
    }

    if (auth.user?.role == 'student') {
      items.add(TabItem('marks', 'My Marks', Icons.assignment_outlined, Icons.assignment, const MyMarksScreen()));
      items.add(TabItem('attendance', 'Attendance', Icons.calendar_today_outlined, Icons.calendar_today, const AttendanceHistoryScreen()));
    }

    items.add(TabItem('announcements', 'News', Icons.campaign_outlined, Icons.campaign, const AnnouncementsScreen()));
    items.add(TabItem('messages', 'Messages', Icons.chat_bubble_outline, Icons.chat_bubble, const ConversationsScreen()));
    items.add(TabItem('notifs', 'Inbox', Icons.inbox_outlined, Icons.inbox, const NotificationDbScreen()));
    items.add(TabItem('alerts', 'Alerts', Icons.notifications_outlined, Icons.notifications, const NotificationsScreen()));

    if (auth.isAdmin || auth.isTeacher) {
      items.add(TabItem('reports', 'Reports', Icons.description_outlined, Icons.description, const ReportsScreen()));
    }

    if (auth.isAdmin) {
      items.add(TabItem('admin', 'Admin', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, const AdminScreen()));
    }

    if (auth.isAdmin || auth.isTeacher) {
      items.add(TabItem('settings', 'Settings', Icons.settings_outlined, Icons.settings, const SettingsScreen()));
    }

    items.add(TabItem('profile', 'Profile', Icons.person_outline, Icons.person, const ProfileScreen()));

    return items;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _lastSeenAlerts = 0;

  void _onTabSelected(int i) {
    final nav = context.read<NavigationProvider>();
    nav.setTab(i);
    final screens = AppShell.buildTabItems(context.read<AuthProvider>());
    if (i < screens.length && screens[i].key == 'alerts') {
      _lastSeenAlerts = context.read<WebSocketProvider>().recentDetections.length;
    }
  }

  /// Returns at most 5 tabs for the bottom bar
  List<TabItem> _bottomTabs(List<TabItem> all, AuthProvider auth) {
    final pinned = <String>['home'];
    if (auth.isAdmin || auth.isTeacher) {
      pinned.addAll(['dashboard', 'cameras', 'students']);
    } else if (auth.isParent) {
      pinned.addAll(['dashboard', 'attendance', 'children']);
    } else if (auth.user?.role == 'student') {
      pinned.addAll(['dashboard', 'attendance', 'marks']);
    } else {
      pinned.addAll(['dashboard', 'announcements', 'alerts']);
    }
    pinned.add('profile');
    return all.where((t) => pinned.contains(t.key)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final ws = context.watch<WebSocketProvider>();
    final nav = context.watch<NavigationProvider>();
    final screens = AppShell.buildTabItems(auth);
    final isDesktop = Responsive.isDesktop(context);
    
    // Give WS provider access to context for live attendance injection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WebSocketProvider>().setContext(context);
    });
    
    final navTabs = _bottomTabs(screens, auth);
    final index = nav.currentIndex;

    // Clamp index if screens changed
    final safeIndex = index >= screens.length ? 0 : index;

    // Find active nav tab index
    final activeNavIndex = navTabs.indexWhere((t) => t.key == screens[safeIndex].key);

    final unreadAlertCount = (ws.recentDetections.length - _lastSeenAlerts).clamp(0, 99);
    final unreadAlerts = screens[safeIndex].key == 'alerts' ? 0 : unreadAlertCount;

    // Desktop layout with side navigation
    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Side Navigation Rail
            NavigationRail(
              selectedIndex: activeNavIndex >= 0 ? activeNavIndex : 0,
              onDestinationSelected: (i) {
                if (i < navTabs.length) {
                  final screenIdx = screens.indexWhere((s) => s.key == navTabs[i].key);
                  if (screenIdx >= 0) _onTabSelected(screenIdx);
                }
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).cardColor,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.face, size: 36, color: AppColors.primary600),
                    const SizedBox(height: 8),
                    Text(
                      'AttendanceAI',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: SizedBox(
                              width: 300,
                              child: AppDrawer(
                                currentIndex: safeIndex,
                                onSelect: (i) {
                                  nav.setTab(i);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              destinations: navTabs.map((item) {
                final hasUnread = item.key == 'alerts' && unreadAlerts > 0;
                return NavigationRailDestination(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(item.icon),
                      if (hasUnread)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error500,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$unreadAlerts',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  selectedIcon: Icon(item.activeIcon),
                  label: Text(item.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Main content
            Expanded(
              child: Column(
                children: [
                  const OfflineBanner(),
                  Expanded(child: screens[safeIndex].screen),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: const ChatbotWidget(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }

    // Mobile layout with bottom navigation (original)
    return Scaffold(
      drawer: AppDrawer(currentIndex: safeIndex, onSelect: (i) { 
        nav.setTab(i); 
        Navigator.pop(context); 
      }),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: screens[safeIndex].screen),
        ],
      ),
      extendBody: true,
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 80),
        child: ChatbotWidget(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B).withOpacity(0.85)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.4)
                    : AppColors.primary500.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: SizedBox(
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(navTabs.length, (i) {
                    final item = navTabs[i];
                    final active = activeNavIndex == i;
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final screenIdx = screens.indexWhere((s) => s.key == item.key);
                          if (screenIdx >= 0) _onTabSelected(screenIdx);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(clipBehavior: Clip.none, children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                padding: EdgeInsets.symmetric(horizontal: active ? 16 : 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: active 
                                      ? (isDark ? AppColors.primary600.withOpacity(0.2) : AppColors.primary50) 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  active ? item.activeIcon : item.icon, 
                                  color: active 
                                      ? AppColors.primary600 
                                      : (isDark ? AppColors.gray400 : AppColors.gray400), 
                                  size: active ? 22 : 20
                                ),
                              ),
                              if (item.key == 'alerts' && unreadAlerts > 0)
                                Positioned(
                                  top: -2, right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: AppColors.error500, shape: BoxShape.circle),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text('$unreadAlerts', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                  ),
                                ),
                              if (item.key == 'notifs')
                                Consumer<NotificationDbProvider>(
                                  builder: (_, np, __) => np.unreadCount > 0
                                      ? Positioned(
                                          top: -2, right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: AppColors.primary600, shape: BoxShape.circle),
                                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                            child: Text('${np.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                            ]),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                color: active 
                                    ? AppColors.primary600 
                                    : (isDark ? AppColors.gray500 : AppColors.gray400), 
                                fontSize: active ? 11 : 10, 
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                fontFamily: 'Outfit'
                              ),
                              child: Text(item.label),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TabItem {
  final String key, label;
  final IconData icon, activeIcon;
  final Widget screen;
  const TabItem(this.key, this.label, this.icon, this.activeIcon, this.screen);
}
