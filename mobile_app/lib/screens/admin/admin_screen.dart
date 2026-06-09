import 'package:flutter/material.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/pocketbase_service.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/responsive.dart';
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
  Map<String, dynamic>? _sysSettings;
  List<dynamic> _auditLogs = [];
  bool _loading = true;
  String? _error;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging || _tab.index != _tabIndex) {
        setState(() => _tabIndex = _tab.index);
      }
    });
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
        ApiClient().get('/admin/system-settings'),
        ApiClient().get('/admin/audit-logs?limit=50'),
      ]);
      setState(() {
        _users = results[0] as List;
        _teachers = results[1] as List;
        _enrollment = results[2];
        _gradeSummary = results[3];
        _sysSettings = results[4] is Map ? Map<String, dynamic>.from(results[4]) : null;
        _auditLogs = results[5] is List ? results[5] as List : [];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  void _showAddTeacherSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddTeacherSheet(),
    );
  }

  void _showAssignCamerasDialog(dynamic teacher) async {
    List<dynamic> assigned = [];
    try {
      assigned = await _service.getTeacherAssignments(teacher['id'].toString());
    } catch (_) {}

    if (!mounted) return;
    final assignedIds = assigned.map((c) => c['id'] as int).toSet();

    showDialog(
      context: context,
      builder: (_) => _AssignCamerasDialog(
        teacher: teacher,
        assignedIds: assignedIds,
        onSave: (ids) => _service.assignCameras(teacher['id'].toString(), ids),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'Admin Panel',
              subtitle: 'Manage users and system',
              action: _tabIndex == 1
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5)),
                      onPressed: _showAddTeacherSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Teacher'),
                    )
                  : null,
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tab,
                labelColor: AppColors.primary600,
                unselectedLabelColor: AppColors.gray500,
                indicatorColor: AppColors.primary600,
                isScrollable: true,
                tabs: const [Tab(text: 'Users'), Tab(text: 'Teachers'), Tab(text: 'Grades'), Tab(text: 'Enrollment'), Tab(text: '⚙️ Settings'), Tab(text: '📋 Audit')],
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
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: Responsive.isDesktop(context) ? 1200 : double.infinity),
                        child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (_, i) {
                          final u = _users[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary100,
                                child: Text((u['full_name'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppColors.primary700, fontWeight: FontWeight.bold)),
                              ),
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
                      ),
                    ),
                    // Teachers
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: Responsive.isDesktop(context) ? 1200 : double.infinity),
                        child: ListView.builder(
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
                            trailing: IconButton(
                              icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary600, size: 20),
                              onPressed: () => _showAssignCamerasDialog(t),
                            ),
                          ),
                        );
                      },
                    ),
                      ),
                    ),
                    // Grades
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: Responsive.isDesktop(context) ? 1200 : double.infinity),
                        child: SingleChildScrollView(
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
                                        child: LinearProgressIndicator(
                                          value: (g['rate'] ?? 0) / 100,
                                          backgroundColor: AppColors.gray200,
                                          valueColor: const AlwaysStoppedAnimation(AppColors.primary500),
                                          minHeight: 8,
                                        ),
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
                      ),
                    ),
                    // Enrollment
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: Responsive.isDesktop(context) ? 1200 : double.infinity),
                        child: SingleChildScrollView(
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
                      ),
                    ),

                    // ── Settings ──────────────────────────────────────────
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: Responsive.isDesktop(context) ? 1200 : double.infinity),
                        child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _sysSettings == null
                          ? const Center(child: CircularProgressIndicator())
                          : Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('System Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 16),
                                  Text('Recognition Threshold: ${(_sysSettings!['recognition_threshold'] as num).toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Slider(
                                    value: (_sysSettings!['recognition_threshold'] as num).toDouble(),
                                    min: 0.5, max: 1.0, divisions: 50,
                                    label: (_sysSettings!['recognition_threshold'] as num).toStringAsFixed(2),
                                    activeColor: AppColors.primary600,
                                    onChanged: (v) => setState(() => _sysSettings!['recognition_threshold'] = v),
                                  ),
                                  const Text('Higher = stricter. Recommended: 0.85–0.95',
                                      style: TextStyle(fontSize: 11, color: AppColors.gray500)),
                                  const SizedBox(height: 16),
                                  Text('Duplicate Window: ${_sysSettings!['duplicate_window_minutes']} min',
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: _sysSettings!['duplicate_window_minutes'].toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Minutes', border: OutlineInputBorder()),
                                        onChanged: (v) => _sysSettings!['duplicate_window_minutes'] = int.tryParse(v) ?? _sysSettings!['duplicate_window_minutes'],
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: () async {
                                        await ApiClient().put('/admin/system-settings', _sysSettings!);
                                        if (mounted) showSnack(context, 'Settings saved');
                                      },
                                      child: const Text('Save Settings'),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                    ),
                      ),
                    ),

                    // ── Audit Log ─────────────────────────────────────────
                    _auditLogs.isEmpty
                        ? const EmptyState(emoji: '📋', title: 'No audit logs yet', subtitle: '')
                        : Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: Responsive.isDesktop(context) ? 1200 : double.infinity),
                              child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _auditLogs.length,
                            itemBuilder: (_, i) {
                              final l = _auditLogs[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  dense: true,
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primary100, borderRadius: BorderRadius.circular(8)),
                                    child: Text(l['action'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.primary700, fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(l['actor'] ?? 'System', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  subtitle: Text('${l['target_type'] ?? ''} ${l['target_id'] ?? ''}', style: const TextStyle(fontSize: 11)),
                                  trailing: Text(
                                    l['timestamp'] != null ? DateTime.parse(l['timestamp']).toLocal().toString().substring(0, 16) : '',
                                    style: const TextStyle(fontSize: 10, color: AppColors.gray400),
                                  ),
                                ),
                              );
                            },
                          ),
                            ),
                          ),
                  ]),
      ),
    );
  }
}

// ── Assign Cameras Dialog ────────────────────────────────────────────────────
class _AssignCamerasDialog extends StatefulWidget {
  final dynamic teacher;
  final Set<int> assignedIds;
  final Future<void> Function(List<int>) onSave;
  const _AssignCamerasDialog({required this.teacher, required this.assignedIds, required this.onSave});

  @override
  State<_AssignCamerasDialog> createState() => _AssignCamerasDialogState();
}

class _AssignCamerasDialogState extends State<_AssignCamerasDialog> {
  late Set<int> _selected;
  List<dynamic> _cameras = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.assignedIds);
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    try {
      final data = await ApiClient().get('/cameras');
      setState(() { _cameras = List.from(data); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Cameras to ${widget.teacher['full_name'] ?? ''}'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _cameras.isEmpty
                ? const Text('No cameras available')
                : ListView(
                    shrinkWrap: true,
                    children: _cameras.map((c) {
                      final id = c['id'] as int;
                      return CheckboxListTile(
                        title: Text(c['name'] ?? 'Camera $id'),
                        subtitle: Text(c['location'] ?? ''),
                        value: _selected.contains(id),
                        onChanged: (v) => setState(() => v! ? _selected.add(id) : _selected.remove(id)),
                      );
                    }).toList(),
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : () async {
            final nav = Navigator.of(context);
            setState(() => _saving = true);
            await widget.onSave(_selected.toList());
            if (mounted) nav.pop();
          },
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Add Teacher Sheet ────────────────────────────────────────────────────────
class _AddTeacherSheet extends StatefulWidget {
  const _AddTeacherSheet();

  @override
  State<_AddTeacherSheet> createState() => _AddTeacherSheetState();
}

class _AddTeacherSheetState extends State<_AddTeacherSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _department = TextEditingController();
  final _employeeId = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await PocketBaseService.register(
        email: _email.text.trim(),
        password: _password.text,
        name: _fullName.text.trim(),
        role: 'teacher',
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      await ApiClient().post(Endpoints.registerTeacher, {
        'email': _email.text.trim(),
        'password': _password.text,
        'full_name': _fullName.text.trim(),
        'department': _department.text.trim(),
        'employee_id': _employeeId.text.trim(),
        if (_phone.text.isNotEmpty) 'phone': _phone.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        showSnack(context, 'Teacher added successfully');
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Teacher', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(_fullName, 'Full Name', required: true),
              _field(_email, 'Email', required: true, keyboard: TextInputType.emailAddress),
              _passField(),
              _field(_department, 'Department', required: true),
              _field(_employeeId, 'Employee ID', required: true),
              _field(_phone, 'Phone (optional)', keyboard: TextInputType.phone),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add Teacher'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool required = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _passField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _password,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'Password',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      ),
    );
  }
}
