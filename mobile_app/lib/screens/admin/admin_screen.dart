import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _service = AdminService();
  List<dynamic> _users = [];
  List<dynamic> _teachers = [];
  dynamic _enrollment;
  dynamic _gradeSummary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getUsers(),
        _service.getTeachers(),
        _service.getEnrollmentStatus(),
        ApiClient().get('/reports/grade-summary'),
      ]);
      setState(() {
        _users = results[0] as List;
        _teachers = results[1] as List;
        _enrollment = results[2];
        _gradeSummary = results[3];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: GradientHeader(title: 'Admin Panel', subtitle: 'Manage users and system')),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.primary600,
                unselectedLabelColor: AppColors.gray500,
                indicatorColor: AppColors.primary600,
                isScrollable: true,
                tabs: const [Tab(text: 'Users'), Tab(text: 'Teachers'), Tab(text: 'Grades'), Tab(text: 'Enrollment')],
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : TabBarView(controller: _tab, children: [
                    // Users
                    RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (_, i) {
                          final u = _users[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: AppColors.primary100, child: Text((u['full_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary700, fontWeight: FontWeight.bold))),
                              title: Text(u['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${u['email']} • ${u['role']}', style: const TextStyle(fontSize: 12)),
                              trailing: Switch(
                                value: u['is_active'] ?? true,
                                onChanged: (_) async { await _service.toggleUser(u['id'].toString()); _load(); },
                                activeColor: AppColors.success500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Teachers
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _teachers.length,
                      itemBuilder: (_, i) {
                        final t = _teachers[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: AppColors.secondary600, child: Icon(Icons.school, color: Colors.white, size: 18)),
                            title: Text(t['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${t['department'] ?? ''} • ${t['employee_id'] ?? ''}', style: const TextStyle(fontSize: 12)),
                          ),
                        );
                      },
                    ),
                    // Grades
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _gradeSummary == null
                          ? const EmptyState(emoji: '📈', title: 'No grade data', subtitle: '')
                          : Column(children: [
                              if (_gradeSummary is Map && _gradeSummary['grades'] != null)
                                ...(_gradeSummary['grades'] as List).map((g) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text(g['grade']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text('${(g['rate'] ?? 0).toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.primary600, fontWeight: FontWeight.bold)),
                                      ]),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(value: (g['rate'] ?? 0) / 100, backgroundColor: AppColors.gray200, valueColor: const AlwaysStoppedAnimation(AppColors.primary500), minHeight: 8),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${g['present'] ?? 0} / ${g['total'] ?? 0} students', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                                    ]),
                                  ),
                                ))
                              else
                                const EmptyState(emoji: '📈', title: 'No grade data', subtitle: ''),
                            ]),
                    ),
                    // Enrollment
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _enrollment == null
                          ? const EmptyState(emoji: '📊', title: 'No data', subtitle: '')
                          : Column(children: [
                              if (_enrollment is List)
                                ...(_enrollment as List).map((e) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(e['grade_level']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    trailing: Text('${e['enrolled'] ?? 0} enrolled', style: const TextStyle(color: AppColors.primary600, fontWeight: FontWeight.w600)),
                                  ),
                                ))
                              else
                                Text(_enrollment.toString()),
                            ]),
                    ),
                  ]),
      ),
    );
  }
}
