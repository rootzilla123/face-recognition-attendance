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
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/attendance/stats_card.dart';

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

    return RefreshIndicator(
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
                sliver: SliverToBoxAdapter(child: Column(children: [
                  // Filter bar
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
                  const SizedBox(height: 16),

                  // Stats (admin/teacher only, today only)
                  if (showStats) ...[
                    GridView.count(
                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55,
                      children: [
                        StatsCard.blue(label: 'Total Students', value: stats?.totalStudents.toString() ?? '—', icon: '👥', subtitle: 'Enrolled'),
                        StatsCard.green(label: 'Present Today', value: stats?.presentStudents.toString() ?? '—', icon: '✅', subtitle: 'Checked in'),
                        StatsCard.red(label: 'Absent Today', value: stats?.absentStudents.toString() ?? '—', icon: '❌', subtitle: 'Not checked in'),
                        StatsCard.purple(label: 'Rate', value: stats != null ? '${stats.attendancePercentage.toStringAsFixed(1)}%' : '—', icon: '📊', subtitle: stats != null && stats.attendancePercentage >= 90 ? 'Excellent!' : 'Good'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Table
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))]),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary50, Color(0xFFFAF5FF)]), borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(_selectedStudentId != null ? att.nameFor(_selectedStudentId!) : 'Attendance Log', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                          if (att.isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ]),
                      ),
                      if (filtered.isEmpty)
                        Padding(padding: const EdgeInsets.all(32), child: Column(children: [
                          const Text('📭', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          Text('No records for ${formatDate(_selectedDate)}', style: const TextStyle(color: AppColors.gray500, fontSize: 13), textAlign: TextAlign.center),
                        ]))
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppColors.gray50),
                            headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray700),
                            dataTextStyle: const TextStyle(fontSize: 12, color: AppColors.gray700),
                            columns: const [DataColumn(label: Text('#')), DataColumn(label: Text('NAME')), DataColumn(label: Text('TIME')), DataColumn(label: Text('LOCATION')), DataColumn(label: Text('CONF.'))],
                            rows: filtered.asMap().entries.map((e) {
                              final r = e.value;
                              return DataRow(cells: [
                                DataCell(Text('${e.key + 1}', style: const TextStyle(color: AppColors.gray500))),
                                DataCell(Text(att.nameFor(r.studentId), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900))),
                                DataCell(Text(formatTime(r.timestamp))),
                                DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary100, borderRadius: BorderRadius.circular(999)), child: Text(r.cameraLocation, style: const TextStyle(fontSize: 10, color: AppColors.primary700, fontWeight: FontWeight.w500)))),
                                DataCell(Text(formatPercent(r.confidenceScore), style: const TextStyle(fontWeight: FontWeight.w600))),
                              ]);
                            }).toList(),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ])),
              ),
            ]),
    );
  }
}
