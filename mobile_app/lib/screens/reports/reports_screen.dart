import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/export_service.dart';
import '../../core/services/reports_service.dart';
import '../../widgets/common/gradient_header.dart';
import '../attendance/clip_player_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DateTime? _start;
  DateTime? _end;
  String? _selectedStudentId;
  String _search = '';

  // Weekly trend + late arrivals state
  Map<String, dynamic>? _weeklyTrend;
  List<dynamic> _lateArrivals = [];
  bool _trendLoading = false;
  bool _lateLoading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        if (_tabs.index == 1 && _weeklyTrend == null) _loadWeeklyTrend();
        if (_tabs.index == 2 && _lateArrivals.isEmpty) _loadLateArrivals();
      }
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _loadWeeklyTrend() async {
    setState(() => _trendLoading = true);
    try {
      final data = await ReportsService().getWeeklyTrend();
      setState(() => _weeklyTrend = data);
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to load trend: $e', error: true);
    }
    setState(() => _trendLoading = false);
  }

  Future<void> _loadLateArrivals() async {
    setState(() => _lateLoading = true);
    try {
      final data = await ReportsService().getLateArrivals();
      setState(() => _lateArrivals = data);
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to load late arrivals: $e', error: true);
    }
    setState(() => _lateLoading = false);
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => isStart ? _start = picked : _end = picked);
  }

  Future<void> _fetch() async {
    if (_start == null || _end == null) {
      showSnack(context, 'Please select both dates', error: true);
      return;
    }
    final startStr = DateFormat('yyyy-MM-dd').format(_start!);
    final endStr = DateFormat('yyyy-MM-dd').format(_end!);
    if (_selectedStudentId != null) {
      try {
        final records = await ReportsService().getStudentReport(_selectedStudentId!, startStr, endStr);
        if (mounted) context.read<AttendanceProvider>().setReportRecords(records);
      } catch (e) {
        if (mounted) showSnack(context, e.toString(), error: true);
      }
    } else {
      await context.read<AttendanceProvider>().fetchByDateRange(startStr, endStr);
    }
  }

  void _downloadTxt() async {
    final records = context.read<AttendanceProvider>().reportRecords;
    if (records.isEmpty) { showSnack(context, 'No records to download', error: true); return; }
    try {
      final path = await ExportService().exportAndShareTxt(records, formatDate(_start!), formatDate(_end!));
      if (mounted) _showSavedDialog(path);
    } catch (e) {
      if (mounted) showSnack(context, 'Export failed: $e', error: true);
    }
  }

  void _downloadCsv() async {
    final records = context.read<AttendanceProvider>().reportRecords;
    if (records.isEmpty) { showSnack(context, 'No records to download', error: true); return; }
    try {
      final path = await ExportService().exportAndShareCsv(records, formatDate(_start!), formatDate(_end!));
      if (mounted) _showSavedDialog(path);
    } catch (e) {
      if (mounted) showSnack(context, 'Export failed: $e', error: true);
    }
  }

  void _downloadPdf() async {
    final records = context.read<AttendanceProvider>().reportRecords;
    if (records.isEmpty) { showSnack(context, 'No records to download', error: true); return; }
    try {
      final names = context.read<AttendanceProvider>().studentNames;
      final path = await ExportService().exportAndSharePdf(records, formatDate(_start!), formatDate(_end!), studentNames: names);
      if (mounted) _showSavedDialog(path);
    } catch (e) {
      if (mounted) showSnack(context, 'Export failed: $e', error: true);
    }
  }

  void _showSavedDialog(String path) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('File Saved'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your report has been saved to:', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: SelectableText(path, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
          ),
          const SizedBox(height: 8),
          const Text('Use a file manager app to open it.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<AttendanceProvider>();
    final students = context.watch<StudentProvider>().students;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(children: [
        GradientHeader(title: 'Reports', subtitle: 'Attendance analytics and exports'),
        TabBar(
          controller: _tabs,
          labelColor: AppColors.primary600,
          unselectedLabelColor: AppColors.gray400,
          indicatorColor: AppColors.primary600,
          tabs: const [
            Tab(text: 'Records'),
            Tab(text: 'Weekly Trend'),
            Tab(text: 'Late Arrivals'),
          ],
        ),
        Expanded(
          child: TabBarView(controller: _tabs, children: [
            // ── Tab 1: Records ──────────────────────────────────────────
            CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Search by student name or location...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                          filled: true, fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _pickDate(true),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(_start != null ? formatDate(_start!) : 'Start Date'),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _pickDate(false),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(_end != null ? formatDate(_end!) : 'End Date'),
                            )),
                          ]),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: prov.isLoading ? null : _fetch,
                              child: prov.isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Fetch Records'),
                            ),
                          ),
                          if (auth.isAdmin || auth.isTeacher) ...[
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String?>(
                              value: _selectedStudentId,
                              decoration: const InputDecoration(labelText: 'Filter by Student (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('All Students')),
                                ...students.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.fullName, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (v) => setState(() => _selectedStudentId = v),
                            ),
                          ],
                        ]),
                      ),
                    ),
                    if (prov.reportRecords.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(onPressed: _downloadTxt, icon: const Icon(Icons.download, size: 16), label: const Text('TXT'))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(onPressed: _downloadCsv, icon: const Icon(Icons.table_chart, size: 16), label: const Text('CSV'))),
                        const SizedBox(width: 8),
                        Expanded(child: FilledButton.icon(onPressed: _downloadPdf, icon: const Icon(Icons.picture_as_pdf, size: 16), label: const Text('PDF'))),
                      ]),
                      const SizedBox(height: 12),
                      _locationBreakdown(prov),
                      const SizedBox(height: 12),
                      _recordsTable(prov, context),
                    ],
                  ]),
                    ),
                  ),
                ),
              ),
            ]),

            // ── Tab 2: Weekly Trend ─────────────────────────────────────
            RefreshIndicator(
              onRefresh: _loadWeeklyTrend,
              child: _trendLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _weeklyTrend == null
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('📈', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          const Text('No trend data yet', style: TextStyle(color: AppColors.gray400)),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _loadWeeklyTrend, child: const Text('Load Trend')),
                        ]))
                      : ListView(padding: const EdgeInsets.all(16), children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const Text('7-Day Attendance Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 16),
                                if (_weeklyTrend!['trend'] is List)
                                  ...(_weeklyTrend!['trend'] as List).map((day) {
                                    final pct = (day['rate'] as num?)?.toDouble() ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                          Text(day['date']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                          Text('${pct.toStringAsFixed(1)}%  (${day['present'] ?? 0}/${day['total'] ?? 0})',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                                  color: pct >= 90 ? AppColors.success600 : pct >= 75 ? AppColors.orange500 : AppColors.error500)),
                                        ]),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct / 100,
                                            minHeight: 8,
                                            backgroundColor: AppColors.gray100,
                                            valueColor: AlwaysStoppedAnimation(
                                              pct >= 90 ? AppColors.success500 : pct >= 75 ? AppColors.orange500 : AppColors.error500,
                                            ),
                                          ),
                                        ),
                                      ]),
                                    );
                                  })
                                else
                                  Text(_weeklyTrend.toString()),
                              ]),
                            ),
                          ),
                        ]),
            ),

            // ── Tab 3: Late Arrivals ────────────────────────────────────
            RefreshIndicator(
              onRefresh: _loadLateArrivals,
              child: _lateLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _lateArrivals.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('⏰', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          const Text('No late arrivals today', style: TextStyle(color: AppColors.gray400)),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _loadLateArrivals, child: const Text('Refresh')),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _lateArrivals.length,
                          itemBuilder: (ctx, i) {
                            final r = _lateArrivals[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: AppColors.orange500.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: const Center(child: Text('⏰', style: TextStyle(fontSize: 20))),
                                ),
                                title: Text(r['full_name']?.toString() ?? r['student_id']?.toString() ?? '—',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                subtitle: Text('${r['grade_level'] ?? ''} • ${r['minutes_late'] ?? 0} min late', style: const TextStyle(fontSize: 12)),
                                trailing: Text(r['arrival_time']?.toString() ?? '—',
                                    style: const TextStyle(color: AppColors.orange500, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            );
                          },
                        ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _locationBreakdown(AttendanceProvider prov) {
    final records = prov.reportRecords;
    final byLocation = <String, int>{};
    for (final r in records) {
      byLocation[r.cameraLocation] = (byLocation[r.cameraLocation] ?? 0) + 1;
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('By Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          ...byLocation.entries.map((e) {
            final frac = e.value / records.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('${e.value} (${(frac * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary600, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: frac, backgroundColor: AppColors.gray100,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary500), minHeight: 6),
                ),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _recordsTable(AttendanceProvider prov, BuildContext context) {
    final filtered = prov.reportRecords.where((r) =>
        _search.isEmpty ||
        context.read<AttendanceProvider>().nameFor(r.studentId).toLowerCase().contains(_search.toLowerCase()) ||
        r.cameraLocation.toLowerCase().contains(_search.toLowerCase())).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${filtered.length} Records', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = Responsive.isDesktop(context) && constraints.maxWidth < 980;
              if (compact) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = filtered[i];
                    return ListTile(
                      dense: true,
                      title: Text(context.read<AttendanceProvider>().nameFor(r.studentId), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${r.cameraLocation} • ${formatDate(r.timestamp)} ${formatTime(r.timestamp)}'),
                      trailing: Text(formatPercent(r.confidenceScore), style: const TextStyle(fontWeight: FontWeight.w700)),
                      onTap: r.clipPath == null ? null : () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ClipPlayerScreen(
                          attendanceId: r.id,
                          studentName: context.read<AttendanceProvider>().nameFor(r.studentId),
                          timestamp: r.timestamp,
                        ),
                      )),
                    );
                  },
                );
              }
              return DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                columns: const [
                  DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Conf.', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Clip', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: filtered.map((r) => DataRow(cells: [
                  DataCell(Text(context.read<AttendanceProvider>().nameFor(r.studentId), style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(r.cameraLocation)),
                  DataCell(Text(formatDate(r.timestamp))),
                  DataCell(Text(formatTime(r.timestamp))),
                  DataCell(Text(formatPercent(r.confidenceScore))),
                  DataCell(r.clipPath != null
                      ? IconButton(
                          icon: const Icon(Icons.play_circle, color: AppColors.primary500),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ClipPlayerScreen(
                              attendanceId: r.id,
                              studentName: context.read<AttendanceProvider>().nameFor(r.studentId),
                              timestamp: r.timestamp,
                            ),
                          )),
                        )
                      : const Icon(Icons.videocam_off, color: AppColors.gray300, size: 20)),
                ])).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }
}
