import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});
  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _profile = await ApiClient().get('/admin/teacher/me');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: GradientHeader(title: 'Teacher Profile', subtitle: 'Your class and camera assignments')),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : _profile == null
                        ? const EmptyState(emoji: '👨‍🏫', title: 'No profile found', subtitle: 'Contact admin to set up your teacher profile')
                        : Column(children: [
                            // Profile card
                            Card(child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(children: [
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(gradient: const LinearGradient(colors: AppColors.purpleGradient), borderRadius: BorderRadius.circular(32)),
                                  child: Center(child: Text((_profile!['full_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                                ),
                                const SizedBox(height: 12),
                                Text(_profile!['full_name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text(_profile!['department'] ?? '', style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
                                const SizedBox(height: 8),
                                if (_profile!['employee_id'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.secondary600.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                                    child: Text('ID: ${_profile!['employee_id']}', style: const TextStyle(color: AppColors.secondary600, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                              ]),
                            )),
                            const SizedBox(height: 12),
                            // Class info
                            if (_profile!['class_name'] != null)
                              Card(child: ListTile(
                                leading: const Icon(Icons.class_outlined, color: AppColors.primary600),
                                title: const Text('Class', style: TextStyle(fontWeight: FontWeight.w600)),
                                trailing: Text(_profile!['class_name'], style: const TextStyle(color: AppColors.primary600, fontWeight: FontWeight.w600)),
                              )),
                            const SizedBox(height: 12),
                            // Assigned cameras
                            if (_profile!['cameras'] != null && (_profile!['cameras'] as List).isNotEmpty) ...[
                              Card(child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('Assigned Cameras', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 10),
                                  ...(_profile!['cameras'] as List).map((c) => ListTile(
                                    dense: true,
                                    leading: Icon(Icons.videocam,
                                        color: c['status'] == 'online' ? AppColors.success500 : AppColors.gray400,
                                        size: 20),
                                    title: Text(c['name'] ?? 'Camera ${c['id']}',
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                    subtitle: Text(c['location'] ?? '', style: const TextStyle(fontSize: 11)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: c['status'] == 'online' ? AppColors.success100 : AppColors.gray100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(c['status'] ?? 'offline',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                              color: c['status'] == 'online' ? AppColors.success700 : AppColors.gray500)),
                                    ),
                                  )),
                                ]),
                              )),
                            ],
                          ]),
          ),
        ),
      ]),
    );
  }
}
