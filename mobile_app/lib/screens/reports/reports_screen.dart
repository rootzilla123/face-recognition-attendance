import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../core/services/export_service.dart';
import '../../core/services/reports_service.dart';
import '../../widgets/common/gradient_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _start;
  DateTime? _end;
  String? _selectedStudentId;

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
      body: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: GradientHeader(title: 'Reports', subtitle: 'Generate and download attendance reports'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            child: prov.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Fetch Records'),
                          ),
                        ),
                        // Student filter (admin/teacher only)
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
                      ],
                    ),
                  ),
                ),
                if (prov.reportRecords.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _downloadTxt,
                      icon: const Icon(Icons.download),
                      label: const Text('Download TXT'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: FilledButton.icon(
                      onPressed: _downloadCsv,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Download CSV'),
                    )),
                  ]),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${prov.reportRecords.length} Records', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                              columns: const [
                                DataColumn(label: Text('Student ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Location', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Confidence', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: prov.reportRecords.map((r) => DataRow(cells: [
                                DataCell(Text(context.read<AttendanceProvider>().nameFor(r.studentId), style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(r.cameraLocation)),
                                DataCell(Text(formatDate(r.timestamp))),
                                DataCell(Text(formatTime(r.timestamp))),
                                DataCell(Text(formatPercent(r.confidenceScore))),
                              ])).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),  // CustomScrollView
    );  // Scaffold
  }
}
