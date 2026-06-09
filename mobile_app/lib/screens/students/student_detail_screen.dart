import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/models/student.dart';
import '../../core/models/attendance.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/pocketbase_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/common/error_state.dart';
import '../teacher/manage_marks_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  List<AttendanceRecord> _records = [];
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
      // Fetch last 30 days of attendance for this student
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));
      final all = await AttendanceService().getByDateRange(
        formatDate(start), formatDate(end),
      );
      _records = all.where((r) => r.studentId == widget.student.id || r.studentId == widget.student.studentId).toList();
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final initials = s.fullName.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final photoUrl = Endpoints.studentPhoto(s.studentId);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 24, left: 16, right: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Column(children: [
                Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                ]),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: CachedNetworkImage(
                      imageUrl: photoUrl,
                      httpHeaders: PocketBaseService.authHeaders,
                      width: 80, height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.white.withValues(alpha: 0.2),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.white.withValues(alpha: 0.2),
                        child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(s.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(s.studentId, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _badge(s.gradeLevel),
                  if (s.section != null) ...[const SizedBox(width: 8), _badge(s.section!)],
                ]),
              ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(children: [
                // Info card
                _infoCard(s),
                const SizedBox(height: 16),

                // Attendance history
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Attendance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                        Text('Last 30 days', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                      ]),
                    ),
                    const Divider(height: 1),
                    if (_loading)
                      const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                    else if (_error != null)
                      ErrorState(message: _error!, onRetry: _load)
                    else if (_records.isEmpty)
                      const EmptyState(emoji: '📋', title: 'No records', subtitle: 'No attendance in the last 30 days')
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _records.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final r = _records[i];
                          return ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: AppColors.success100, borderRadius: BorderRadius.circular(20)),
                              child: const Icon(Icons.check, color: AppColors.success600, size: 20),
                            ),
                            title: Text(formatDate(r.timestamp), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(r.cameraLocation, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(formatTime(r.timestamp), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              Text('${(r.confidenceScore * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: AppColors.success600)),
                            ]),
                          );
                        },
                      ),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
  );

  Widget _infoCard(Student s) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _infoRow(Icons.phone_outlined, 'Parent Phone', s.parentPhone),
      const Divider(height: 20),
      _infoRow(Icons.email_outlined, 'Parent Email', s.parentEmail),
      if (s.parentName != null) ...[const Divider(height: 20), _infoRow(Icons.person_outline, 'Parent Name', s.parentName!)],
      const Divider(height: 20),
      _infoRow(Icons.check_circle_outline, 'Status', s.isActive ? 'Active' : 'Inactive'),
      
      // Manage Marks button for teachers/admins
      Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.user?.role == 'teacher' || auth.user?.role == 'admin') {
            return Column(children: [
              const Divider(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageMarksScreen(student: s))),
                  icon: const Icon(Icons.assignment_outlined),
                  label: const Text('Manage Examination Marks'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]);
          }
          return const SizedBox.shrink();
        },
      ),
    ]),
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, size: 18, color: AppColors.primary600),
    const SizedBox(width: 12),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
    ]),
  ]);
}
