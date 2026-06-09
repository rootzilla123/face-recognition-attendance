import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../common/app_logo.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const AppDrawer({super.key, required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stats = context.watch<AttendanceProvider>().stats;
    final user = auth.user;
    final pct = stats?.attendancePercentage ?? 0;
    final present = stats?.presentStudents ?? 0;
    final total = stats?.totalStudents ?? 0;

    final items = _buildItems(auth);

    return Drawer(
      width: 300,
      backgroundColor: AppColors.sidebarDark,
      child: Column(children: [
        // Logo & Brand
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24, left: 24, right: 24, bottom: 32),
          child: const AppLogo(size: 40),
        ),

        // Nav items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final active = currentIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(i);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: active ? Colors.white.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: active ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
                    ),
                    child: Row(children: [
                      Text(item.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name, 
                          style: TextStyle(
                            color: active ? Colors.white : AppColors.gray400, 
                            fontSize: 14, 
                            fontWeight: active ? FontWeight.bold : FontWeight.w500
                          )
                        ),
                        Text(item.desc, style: TextStyle(color: active ? AppColors.primary300 : AppColors.gray600, fontSize: 11)),
                      ])),
                      if (active) 
                        Container(
                          width: 6, height: 6, 
                          decoration: const BoxDecoration(color: AppColors.primary500, shape: BoxShape.circle)
                        ).animate().scale(duration: 400.ms),
                    ]),
                  ),
                ),
              ).animate().fadeIn(delay: (50 * i).ms).slideX(begin: -0.1);
            },
          ),
        ),

        // Status Card
        if (auth.isAdmin || auth.isTeacher)
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: AppColors.glass(opacity: 0.05, borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("LIVE STATUS", style: TextStyle(color: AppColors.gray500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF4ADE80).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [
                    Text('Active', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1))),
              Text('$present / $total present', style: const TextStyle(color: AppColors.gray400, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct / 100, 
                  backgroundColor: Colors.white.withOpacity(0.05), 
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary500), 
                  minHeight: 8
                ),
              ).animate().shimmer(delay: 1.seconds, duration: 2.seconds),
            ]),
          ),

        // User Profile
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.secondary500, Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                   BoxShadow(color: AppColors.secondary500.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Center(child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              )),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.fullName ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              Text(user?.role.toUpperCase() ?? '', style: const TextStyle(color: AppColors.gray500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ])),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.gray500, size: 20),
              onPressed: () => auth.logout(),
            ),
          ]),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ]),
    );
  }

  List<_NavItem> _buildItems(AuthProvider auth) {
    final items = <_NavItem>[
      const _NavItem('Home', '🏠', 'Activity Feed'),
      const _NavItem('Dashboard', '📊', 'Analytics'),
    ];
    if (auth.isAdmin || auth.isTeacher) {
      items.add(const _NavItem('Live Cameras', '📹', 'Monitoring'));
      items.add(const _NavItem('Students', '👥', 'Management'));
    }
    if (auth.isParent) {
      items.add(const _NavItem('My Children', '👨‍👧', 'Tracking'));
    }
    if (auth.user?.role == 'student') {
      items.add(const _NavItem('My Marks', '📝', 'Examination Results'));
    }
    items.add(const _NavItem('Announcements', '📢', 'News & Records'));
    items.add(const _NavItem('Messages', '💬', 'Direct Chat'));
    items.add(const _NavItem('Inbox', '📬', 'System Notifications'));
    items.add(const _NavItem('Alerts', '🔔', 'Live Events'));
    if (auth.isAdmin || auth.isTeacher) {
      items.add(const _NavItem('Reports', '📄', 'Intelligence Logs'));
    }
    if (auth.isAdmin) {
      items.add(const _NavItem('Admin', '🛡️', 'System Setup'));
    }
    if (auth.isAdmin || auth.isTeacher) {
      items.add(const _NavItem('Settings', '⚙️', 'App Preferences'));
    }
    items.add(const _NavItem('Profile', '👤', 'Account Settings'));
    return items;
  }
}

class _NavItem {
  final String name, icon, desc;
  const _NavItem(this.name, this.icon, this.desc);
}
