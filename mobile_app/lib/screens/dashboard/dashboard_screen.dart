import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/attendance.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/attendance/stats_card.dart';
import '../../widgets/charts/analytics_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  DateTime _selectedDate = DateTime.now();
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().fetchToday();
      context.read<StudentProvider>().fetchStudents();
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _isToday) context.read<AttendanceProvider>().fetchToday();
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (!mounted || picked == null || picked == _selectedDate) return;
    setState(() => _selectedDate = picked);
    final dateStr = DateFormat('yyyy-MM-dd').format(picked);
    final isToday = picked.year == DateTime.now().year && picked.month == DateTime.now().month && picked.day == DateTime.now().day;
    if (!isToday) {
      context.read<AttendanceProvider>().fetchByDateRange(dateStr, dateStr);
    } else {
      context.read<AttendanceProvider>().fetchToday();
    }
  }

  List<AttendanceRecord> get _filtered {
    final att = context.read<AttendanceProvider>();
    final records = _isToday ? att.todayRecords : att.reportRecords;
    if (_selectedStudentId == null) return records;
    return records.where((r) => r.studentId == _selectedStudentId).toList();
  }

  @override
  Widget build(BuildContext context) {
    final att = context.watch<AttendanceProvider>();
    final students = context.watch<StudentProvider>().students;
    final auth = context.watch<AuthProvider>();
    final stats = att.stats;
    final filtered = _filtered;
    final showStats = _isToday && _selectedStudentId == null && (auth.isAdmin || auth.isTeacher);

    if (att.isLoading && att.todayRecords.isEmpty && att.error == null) {
      return const Scaffold(backgroundColor: AppColors.gray50, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      floatingActionButton: (auth.isAdmin || auth.isTeacher)
          ? FloatingActionButton(
              onPressed: () => _showManualAttendanceDialog(students),
              backgroundColor: AppColors.primary600,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: () => context.read<AttendanceProvider>().fetchToday(),
        child: att.error != null && att.todayRecords.isEmpty
            ? ErrorState(message: att.error!, onRetry: () => context.read<AttendanceProvider>().fetchToday())
            : CustomScrollView(slivers: [
                SliverToBoxAdapter(child: GradientHeader(
                  title: 'Dashboard',
                  subtitle: _isToday ? "Today's attendance" : 'Viewing ${formatDate(_selectedDate)}',
                )),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(children: [
                    // Filter bar (existing code remains...)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Filters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.gray700)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _isToday ? AppColors.primary50 : AppColors.warning50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _isToday ? AppColors.primary100 : AppColors.warning500),
                              ),
                              child: Row(children: [
                                Icon(Icons.calendar_today, size: 14, color: _isToday ? AppColors.primary600 : AppColors.orange700),
                                const SizedBox(width: 6),
                                Expanded(child: Text(_isToday ? 'Today' : formatDate(_selectedDate), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _isToday ? AppColors.primary700 : AppColors.orange700))),
                                if (!_isToday) GestureDetector(onTap: () { setState(() => _selectedDate = DateTime.now()); context.read<AttendanceProvider>().fetchToday(); }, child: const Icon(Icons.close, size: 14, color: AppColors.gray500)),
                              ]),
                            ),
                          )),
                          if (auth.isAdmin || auth.isTeacher) ...[
                            const SizedBox(width: 10),
                            Expanded(child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: _selectedStudentId != null ? AppColors.success50 : AppColors.gray50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _selectedStudentId != null ? AppColors.success500 : AppColors.gray200),
                              ),
                              child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
                                value: _selectedStudentId,
                                isExpanded: true,
                                hint: const Text('All Students', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                                style: const TextStyle(fontSize: 12, color: AppColors.gray900, fontWeight: FontWeight.w600),
                                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.gray400),
                                items: [
                                  const DropdownMenuItem<String?>(value: null, child: Text('All Students', style: TextStyle(fontSize: 12))),
                                  ...students.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.fullName, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (v) => setState(() => _selectedStudentId = v),
                              )),
                            )),
                          ],
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 32),

                    // Stats (admin/teacher only, today only)
                    if (showStats) ...[
                      GridView.count(
                        crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.4,
                        children: [
                          StatsCard.blue(label: 'Total Students', value: stats?.totalStudents.toString() ?? '—', icon: '👥', subtitle: 'Enrolled', index: 0),
                          StatsCard.green(label: 'Present Today', value: stats?.presentStudents.toString() ?? '—', icon: '✅', subtitle: 'Checked in', index: 1),
                          StatsCard.red(label: 'Absent Today', value: stats?.absentStudents.toString() ?? '—', icon: '❌', subtitle: 'Not checked in', index: 2),
                          StatsCard.purple(label: 'Rate', value: stats != null ? '${stats.attendancePercentage.toStringAsFixed(1)}%' : '—', icon: '📊', subtitle: stats != null && stats.attendancePercentage >= 90 ? 'Excellent!' : 'Good', index: 3),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const AnalyticsWidget(),
                      const SizedBox(height: 24),
                    ],

                    // Records panel
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(24), 
                        boxShadow: AppColors.premiumShadow,
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                            border: const Border(bottom: BorderSide(color: AppColors.gray100)),
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(_selectedStudentId != null ? att.nameFor(_selectedStudentId!) : 'Attendance Log', 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900, letterSpacing: -0.3)),
                            if (att.isLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary500)),
                          ]),
                        ),
                        if (filtered.isEmpty)
                          Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(children: [
                            const Text('📭', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('No records for ${formatDate(_selectedDate)}', 
                              style: const TextStyle(color: AppColors.gray400, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                          ])))
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = Responsive.isDesktop(context) && constraints.maxWidth < 980;
                              if (compact) {
                                return ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final r = filtered[i];
                                    return ListTile(
                                      dense: true,
                                      title: Text(att.nameFor(r.studentId), style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text('${r.cameraLocation}  •  ${formatTime(r.timestamp)}'),
                                      trailing: Text(
                                        formatPercent(r.confidenceScore),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: r.confidenceScore > 0.8 ? AppColors.success600 : AppColors.warning500,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                              return SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(Colors.transparent),
                                  headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray400, letterSpacing: 0.5),
                                  dataTextStyle: const TextStyle(fontSize: 13, color: AppColors.gray700, fontWeight: FontWeight.w500),
                                  horizontalMargin: 20,
                                  columnSpacing: 24,
                                  columns: [
                                    const DataColumn(label: Text('#')),
                                    const DataColumn(label: Text('STUDENT')),
                                    const DataColumn(label: Text('TIME')),
                                    const DataColumn(label: Text('LOCATION')),
                                    const DataColumn(label: Text('CONF.')),
                                    if (auth.isAdmin || auth.isTeacher) const DataColumn(label: Text('ACTION')),
                                  ],
                                  rows: filtered.asMap().entries.map((e) {
                                    final r = e.value;
                                    return DataRow(cells: [
                                      DataCell(Text('${e.key + 1}', style: const TextStyle(color: AppColors.gray300, fontWeight: FontWeight.bold))),
                                      DataCell(Text(att.nameFor(r.studentId), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gray900))),
                                      DataCell(Text(formatTime(r.timestamp))),
                                      DataCell(Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(8)),
                                        child: Text(r.cameraLocation, style: const TextStyle(fontSize: 10, color: AppColors.primary700, fontWeight: FontWeight.bold)),
                                      )),
                                      DataCell(Text(formatPercent(r.confidenceScore), style: TextStyle(fontWeight: FontWeight.bold, color: r.confidenceScore > 0.8 ? AppColors.success600 : AppColors.warning500))),
                                      if (auth.isAdmin || auth.isTeacher) const DataCell(
                                        Icon(Icons.check_circle_rounded, color: AppColors.success500, size: 22),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                      ]),
                    ),
                    const SizedBox(height: 32),
                  ])),
                    ),
                  )),
              ]),
      ),
    );
  }

  void _showManualAttendanceDialog(List<dynamic> students) {
    String? selectedStudentId;
    String location = 'Main Entrance';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Manual Attendance'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select Student'),
              value: selectedStudentId,
              items: students.map((s) => DropdownMenuItem<String>(value: s.studentId, child: Text(s.fullName))).toList(),
              onChanged: (v) => setDialogState(() => selectedStudentId = v),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Location'),
              onChanged: (v) => location = v,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (selectedStudentId == null) return;
              context.read<AttendanceProvider>().createManualAttendance(selectedStudentId!, location);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
