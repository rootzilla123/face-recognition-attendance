import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/models/student.dart';
import '../../core/models/mark.dart';
import '../../providers/mark_provider.dart';
import '../../core/services/mark_service.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';

class ManageMarksScreen extends StatefulWidget {
  final Student student;
  const ManageMarksScreen({super.key, required this.student});

  @override
  State<ManageMarksScreen> createState() => _ManageMarksScreenState();
}

class _ManageMarksScreenState extends State<ManageMarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarkProvider>().fetchMarks(studentId: widget.student.studentId);
    });
  }

  void _showBulkUpload() async {
    final termCtrl = TextEditingController(text: 'Term 1 2026');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bulk Upload CSV'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('CSV format: student_id, subject, score, max_score, remarks',
              style: TextStyle(fontSize: 12, color: AppColors.gray500)),
          const SizedBox(height: 12),
          TextField(controller: termCtrl, decoration: const InputDecoration(labelText: 'Term', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final picker = ImagePicker();
              // Use file picker via gallery (workaround — ideally use file_picker package)
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked == null || !mounted) return;
              showDialog(context: context, barrierDismissible: false,
                  builder: (_) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Uploading...')])));
              try {
                final result = await MarkService().bulkUpload(picked.path, termCtrl.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  showSnack(context, 'Done: ${result['success']} saved, ${result['failed']} failed');
                  context.read<MarkProvider>().fetchMarks(studentId: widget.student.studentId);
                }
              } catch (e) {
                if (mounted) { Navigator.pop(context); showSnack(context, 'Upload failed: $e', error: true); }
              }
            },
            child: const Text('Pick CSV'),
          ),
        ],
      ),
    );
  }

  void _showSubjectAnalytics() async {
    final subjects = context.read<MarkProvider>().marks.map((m) => m.subject).toSet().toList();
    final terms = context.read<MarkProvider>().marks.map((m) => m.term).toSet().toList();
    if (subjects.isEmpty) { showSnack(context, 'No marks to analyse', error: true); return; }

    String selectedSubject = subjects.first;
    String selectedTerm = terms.isNotEmpty ? terms.first : 'Term 1 2026';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Subject Analytics'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: selectedSubject,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
              items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setS(() => selectedSubject = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedTerm,
              decoration: const InputDecoration(labelText: 'Term', border: OutlineInputBorder()),
              items: terms.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setS(() => selectedTerm = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                showDialog(context: context, barrierDismissible: false,
                    builder: (_) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Loading...')])));
                try {
                  final data = await MarkService().getSubjectAnalytics(selectedSubject, selectedTerm);
                  if (!mounted) return;
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('$selectedSubject — $selectedTerm'),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        _statRow('Students', '${data['student_count']}'),
                        _statRow('Average', '${data['average_percentage']}%'),
                        _statRow('Highest', '${data['highest_percentage']}%'),
                        _statRow('Lowest', '${data['lowest_percentage']}%'),
                      ]),
                      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                    ),
                  );
                } catch (e) {
                  if (mounted) { Navigator.pop(context); showSnack(context, 'Failed: $e', error: true); }
                }
              },
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: AppColors.gray600)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary700)),
    ]),
  );

  void _showConsolidatedReport() async {
    final terms = context.read<MarkProvider>().marks.map((m) => m.term).toSet().toList();
    if (terms.isEmpty) { showSnack(context, 'No marks available', error: true); return; }

    String selectedTerm = terms.first;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Consolidated Report'),
          content: DropdownButtonFormField<String>(
            value: selectedTerm,
            decoration: const InputDecoration(labelText: 'Term', border: OutlineInputBorder()),
            items: terms.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setS(() => selectedTerm = v!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                showDialog(context: context, barrierDismissible: false,
                    builder: (_) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Generating...')])));
                try {
                  final data = await MarkService().getConsolidatedReport(widget.student.studentId, selectedTerm);
                  if (!mounted) return;
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('${widget.student.fullName} — $selectedTerm'),
                      content: SingleChildScrollView(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          _statRow('Overall', '${data['overall_percentage']}%'),
                          _statRow('Grade', data['overall_grade'] ?? '—'),
                          _statRow('Total Score', '${data['total_score']}/${data['total_max']}'),
                          const Divider(),
                          ...(data['marks'] as List? ?? []).map((m) => ListTile(
                            dense: true,
                            title: Text(m['subject'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('${m['score']}/${m['max_score']}'),
                            trailing: Text(m['grade'] ?? '${m['percentage']}%',
                                style: const TextStyle(color: AppColors.primary600, fontWeight: FontWeight.bold)),
                          )),
                        ]),
                      ),
                      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                    ),
                  );
                } catch (e) {
                  if (mounted) { Navigator.pop(context); showSnack(context, 'Failed: $e', error: true); }
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkDialog([Mark? mark]) {
    final subjectCtrl = TextEditingController(text: mark?.subject);
    final termCtrl = TextEditingController(text: mark?.term);
    final scoreCtrl = TextEditingController(text: mark?.score.toString() ?? '0');
    final maxScoreCtrl = TextEditingController(text: mark?.maxScore.toString() ?? '100');
    final gradeCtrl = TextEditingController(text: mark?.grade);
    final remarksCtrl = TextEditingController(text: mark?.remarks);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mark == null ? 'Add Mark' : 'Edit Mark'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
            TextField(controller: termCtrl, decoration: const InputDecoration(labelText: 'Term')),
            Row(children: [
              Expanded(child: TextField(controller: scoreCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Score'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: maxScoreCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Score'))),
            ]),
            TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Grade (Optional)')),
            TextField(controller: remarksCtrl, decoration: const InputDecoration(labelText: 'Remarks (Optional)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final data = {
                'student_id': widget.student.studentId,
                'subject': subjectCtrl.text.trim(),
                'term': termCtrl.text.trim(),
                'score': double.tryParse(scoreCtrl.text) ?? 0,
                'max_score': double.tryParse(maxScoreCtrl.text) ?? 100,
                'grade': gradeCtrl.text.trim().isEmpty ? null : gradeCtrl.text.trim(),
                'remarks': remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim(),
              };
              Navigator.pop(ctx);
              bool ok;
              if (mark == null) {
                ok = await context.read<MarkProvider>().createMark(data);
              } else {
                ok = await context.read<MarkProvider>().updateMark(mark.id, data);
              }
              if (mounted) {
                showSnack(context, ok ? 'Success!' : 'Failed', error: !ok);
                context.read<MarkProvider>().fetchMarks(studentId: widget.student.studentId);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MarkProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: GradientHeader(
          title: 'Marks: ${widget.student.fullName}',
          subtitle: 'Manage examination results',
          action: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.upload_file, color: Colors.white), onPressed: _showBulkUpload, tooltip: 'Bulk Upload CSV'),
            IconButton(icon: const Icon(Icons.bar_chart, color: Colors.white), onPressed: _showSubjectAnalytics, tooltip: 'Subject Analytics'),
            IconButton(icon: const Icon(Icons.summarize, color: Colors.white), onPressed: _showConsolidatedReport, tooltip: 'Consolidated Report'),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: () async {
                if (prov.marks.isEmpty) { showSnack(context, 'No marks to export', error: true); return; }
                showDialog(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Generating PDF...')])));
                try {
                  await ExportService().exportAndShareMarksPdf(prov.marks, widget.student);
                } catch (e) {
                  if (mounted) showSnack(context, 'Error: $e', error: true);
                } finally { if (mounted) Navigator.pop(context); }
              },
              tooltip: 'Export PDF',
            ),
            IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ]),
        )),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: prov.marks.isNotEmpty ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gray100)),
              child: Row(children: [
                const Icon(Icons.analytics, color: AppColors.primary600, size: 24),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('STUDENT AVERAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.gray400, letterSpacing: 0.5)),
                  Text('${(prov.marks.map((m) => m.percentage).reduce((a, b) => a + b) / prov.marks.length).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                ]),
              ]),
            ) : const SizedBox.shrink(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: prov.isLoading
              ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
              : prov.marks.isEmpty
                  ? SliverToBoxAdapter(child: EmptyState(
                      emoji: '📝',
                      title: 'No marks recorded',
                      subtitle: 'Add the first examination mark for this student',
                      action: FilledButton.icon(onPressed: () => _showMarkDialog(), icon: const Icon(Icons.add), label: const Text('Add Mark')),
                    ))
                  : SliverList(delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final m = prov.marks[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(m.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${m.term} • ${m.grade ?? '${m.percentage}%'}'),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (!m.isPublished)
                                IconButton(
                                  icon: const Icon(Icons.rocket_launch, color: Colors.blue),
                                  onPressed: () async {
                                    final ok = await prov.publishMark(m.id);
                                    if (mounted) {
                                      showSnack(context, ok ? 'Published!' : 'Failed', error: !ok);
                                      prov.fetchMarks(studentId: widget.student.studentId);
                                    }
                                  },
                                  tooltip: 'Publish',
                                ),
                              IconButton(icon: const Icon(Icons.edit, color: AppColors.primary600), onPressed: () => _showMarkDialog(m)),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete?'),
                                      content: const Text('Remove this mark?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) await prov.deleteMark(m.id);
                                },
                              ),
                            ]),
                          ),
                        );
                      },
                      childCount: prov.marks.length,
                    )),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMarkDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
