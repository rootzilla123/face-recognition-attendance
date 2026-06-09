import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../core/utils/app_theme.dart';
import '../shell.dart';

class RolePickerScreen extends StatefulWidget {
  final String googleName;
  const RolePickerScreen({super.key, required this.googleName});

  @override
  State<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends State<RolePickerScreen> {
  String? _selected;
  bool _loading = false;

  static const _roles = [
    {'value': 'admin', 'label': 'Admin', 'icon': '🛡️', 'desc': 'Full system access'},
    {'value': 'teacher', 'label': 'Teacher', 'icon': '👩‍🏫', 'desc': 'Manage your class'},
    {'value': 'student', 'label': 'Student', 'icon': '🎓', 'desc': 'Track your attendance'},
    {'value': 'parent', 'label': 'Parent', 'icon': '👨‍👩‍👧', 'desc': 'Monitor your child'},
  ];

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().completeGoogleSignIn(_selected!);
    setState(() => _loading = false);
    if (ok && mounted) {
      context.read<WebSocketProvider>().connect();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF030712), Color(0xFF0F172A), Color(0xFF0C1445)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text('Welcome, ${widget.googleName.split(' ').first}! 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Choose your role to get started',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 40),
                ..._roles.map((r) => _RoleTile(
                  value: r['value']!,
                  label: r['label']!,
                  icon: r['icon']!,
                  desc: r['desc']!,
                  selected: _selected == r['value'],
                  onTap: () => setState(() => _selected = r['value']),
                )),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_selected == null || _loading) ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      disabledBackgroundColor: AppColors.primary600.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String value, label, icon, desc;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile({required this.value, required this.label, required this.icon, required this.desc, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary600.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary500 : Colors.white.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ])),
          if (selected) const Icon(Icons.check_circle, color: AppColors.primary500),
        ]),
      ),
    );
  }
}
