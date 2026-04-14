import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';

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

    // Build nav items matching shell exactly
    final items = _buildItems(auth);

    return Drawer(
      width: 280,
      backgroundColor: AppColors.sidebarDark,
      child: Column(children: [
        // Logo
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 20),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.gray700))),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary500, AppColors.secondary600]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text('📸', style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AttendanceAI', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              Text('Face Recognition System', style: TextStyle(color: AppColors.gray400, fontSize: 11)),
            ]),
          ]),
        ),

        // Nav items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final active = currentIndex == i;
              return GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: active ? const LinearGradient(colors: [AppColors.primary700, AppColors.secondary600]) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Text(item.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.name, style: TextStyle(color: active ? Colors.white : AppColors.gray200, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(item.desc, style: TextStyle(color: active ? const Color(0xFFBFDBFE) : AppColors.gray400, fontSize: 11)),
                    ])),
                    if (active) Container(width: 4, height: 32, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  ]),
                ),
              );
            },
          ),
        ),

        // Live stats (admin/teacher only)
        if (auth.isAdmin || auth.isTeacher)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success500.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Today's Attendance", style: TextStyle(color: AppColors.gray200, fontSize: 12, fontWeight: FontWeight.w600)),
                Row(children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Live', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11)),
                ]),
              ]),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold))),
              Text('$present of $total students present', style: const TextStyle(color: AppColors.gray300, fontSize: 12)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct / 100, backgroundColor: AppColors.gray700, valueColor: const AlwaysStoppedAnimation(AppColors.success500), minHeight: 6),
              ),
            ]),
          ),

        // User profile
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.gray700))),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.secondary500, Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(child: Text(
                user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.fullName ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(user?.role ?? '', style: const TextStyle(color: AppColors.gray400, fontSize: 11)),
            ])),
          ]),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ]),
    );
  }

  List<_NavItem> _buildItems(AuthProvider auth) {
    final items = <_NavItem>[
      const _NavItem('Home', '🏠', 'Welcome'),
      const _NavItem('Dashboard', '📊', 'Overview & Stats'),
    ];
    if (auth.isAdmin || auth.isTeacher) {
      items.add(const _NavItem('Live Cameras', '📹', 'Monitor Feeds'));
      items.add(const _NavItem('Students', '👥', 'Manage Students'));
    }
    if (auth.isParent) {
      items.add(const _NavItem('My Children', '👨‍👧', 'Track Attendance'));
    }
    items.add(const _NavItem('Announcements', '📢', 'School News'));
    items.add(const _NavItem('Inbox', '📬', 'Notifications'));
    items.add(const _NavItem('Alerts', '🔔', 'Live Events'));
    if (auth.isAdmin || auth.isTeacher) {
      items.add(const _NavItem('Reports', '📄', 'Download Reports'));
    }
    if (auth.isAdmin) {
      items.add(const _NavItem('Admin', '🛡️', 'Manage System'));
    }
    if (auth.isAdmin || auth.isTeacher) {
      items.add(const _NavItem('Settings', '⚙️', 'Configuration'));
    }
    items.add(const _NavItem('Profile', '👤', 'My Account'));
    return items;
  }
}

class _NavItem {
  final String name, icon, desc;
  const _NavItem(this.name, this.icon, this.desc);
}
