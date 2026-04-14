import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/common/gradient_header.dart';
import '../auth/login_screen.dart';
import '../preferences/preferences_screen.dart';
import '../teacher/teacher_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final initials = user.fullName.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final roleColor = _roleColor(user.role);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: GradientHeader(title: 'Profile', subtitle: user.email)),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(children: [
              // Avatar card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [roleColor, roleColor.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(36)),
                      child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(height: 12),
                    Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                      child: Text(user.role.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              // Menu items
              Card(
                child: Column(children: [
                  _menuItem(context, Icons.notifications_outlined, 'Notification Preferences', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferencesScreen()))),
                  const Divider(height: 1),
                  if (user.isTeacher)
                    _menuItem(context, Icons.school_outlined, 'My Class & Cameras', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherProfileScreen()))),
                  if (user.isTeacher) const Divider(height: 1),
                  _menuItem(context, Icons.info_outline, 'About', () {}),
                  const Divider(height: 1),
                  _menuItem(context, Icons.logout, 'Sign Out', () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                    }
                  }, color: AppColors.error500),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return AppColors.error600;
      case 'teacher': return AppColors.secondary600;
      case 'parent': return AppColors.success600;
      default: return AppColors.primary600;
    }
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.gray600, size: 20),
      title: Text(label, style: TextStyle(color: color ?? AppColors.gray900, fontSize: 14)),
      trailing: color == null ? const Icon(Icons.chevron_right, color: AppColors.gray400, size: 18) : null,
      onTap: onTap,
      dense: true,
    );
  }
}
