import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/parent_provider.dart';
import '../../providers/mark_provider.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';
import 'fees_screen.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});
  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  final _linkCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ParentProvider>().fetchChildren());
  }

  void _showLink() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Link Child'),
        content: TextField(controller: _linkCtrl, decoration: const InputDecoration(labelText: 'Student ID', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<ParentProvider>().linkChild(_linkCtrl.text.trim());
              _linkCtrl.clear();
              if (mounted) showSnack(context, ok ? 'Child linked!' : context.read<ParentProvider>().error ?? 'Failed', error: !ok);
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ParentProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: () => context.read<ParentProvider>().fetchChildren(),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: GradientHeader(
            title: 'My Children',
            subtitle: 'Track your children\'s attendance',
            action: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary600),
              onPressed: _showLink,
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Link Child'),
            ),
          )),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: prov.isLoading
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : prov.children.isEmpty
                    ? SliverToBoxAdapter(child: EmptyState(
                        emoji: '👨‍👧',
                        title: 'No children linked',
                        subtitle: 'Link your child using their Student ID',
                        action: FilledButton.icon(onPressed: _showLink, icon: const Icon(Icons.link), label: const Text('Link Child')),
                      ))
                    : SliverList(delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final child = prov.children[i];
                          final attendance = prov.childAttendance[child.studentId] ?? [];
                          final feesData = prov.childFees[child.studentId];
                          final fees = feesData == null ? null : (feesData['fees'] as List? ?? []);
                          return ExpansionTile(
                            leading: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: AppColors.blueGradient), borderRadius: BorderRadius.circular(22)),
                              child: Center(child: Text(child.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ),
                            title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${child.gradeLevel}${child.section != null ? ' • ${child.section}' : ''}', style: const TextStyle(fontSize: 12)),
                            onExpansionChanged: (open) {
                              if (open) {
                                context.read<ParentProvider>().fetchChildAttendance(child.studentId);
                                context.read<ParentProvider>().fetchChildFees(child.studentId);
                                context.read<MarkProvider>().fetchChildMarks(child.studentId);
                              }
                            },
                            children: [
                              // Fees section
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: Row(children: [
                                  const Icon(Icons.receipt_long, size: 16, color: AppColors.primary600),
                                  const SizedBox(width: 6),
                                  const Text('Fee Balance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  if (feesData != null) ...[
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.primary600.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Text(
                                        'Owed: \$${(feesData['total_owed'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.primary600, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FeesScreen(child: child))),
                                      child: const Text('Full →', style: TextStyle(fontSize: 11, color: AppColors.primary600, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ]),
                              ),
                              if (fees == null)
                                const Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                              else if (fees.isEmpty)
                                const Padding(padding: EdgeInsets.all(12), child: Text('No fee records', style: TextStyle(fontSize: 12, color: AppColors.gray500)))
                              else
                                ...fees.map((f) => ListTile(
                                  dense: true,
                                  leading: Icon(
                                    f['is_paid'] ? Icons.check_circle : Icons.pending,
                                    color: f['is_paid'] ? AppColors.success500 : Colors.orange,
                                    size: 18,
                                  ),
                                  title: Text(f['fee_type'], style: const TextStyle(fontSize: 13)),
                                  subtitle: Text(
                                    '${f['term'] ?? ''}${f['due_date'] != null ? ' • Due: ${f['due_date'].toString().substring(0, 10)}' : ''}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: Text(
                                    '\$${(f['amount'] as num).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: f['is_paid'] ? AppColors.success500 : Colors.orange,
                                    ),
                                  ),
                                )),
                              const Divider(height: 16),
                              // Marks section
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Row(children: [
                                  const Icon(Icons.assignment_outlined, size: 16, color: AppColors.primary600),
                                  const SizedBox(width: 6),
                                  const Text('Examination Results', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const Spacer(),
                                  Consumer<MarkProvider>(
                                    builder: (context, mp, _) {
                                      final marks = mp.childMarks[child.studentId];
                                      if (marks == null || marks.isEmpty) return const SizedBox.shrink();
                                      return IconButton(
                                        icon: const Icon(Icons.picture_as_pdf, size: 18, color: AppColors.primary600),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          showDialog(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Generating Report...')])));
                                          try {
                                            await ExportService().exportAndShareMarksPdf(marks, child);
                                          } catch (e) {
                                            if (context.mounted) showSnack(context, 'Error: $e', error: true);
                                          } finally { if (context.mounted) Navigator.pop(context); }
                                        },
                                        tooltip: 'Download Report Card',
                                      );
                                    },
                                  ),
                                ]),
                              ),
                              Consumer<MarkProvider>(
                                builder: (context, markProv, _) {
                                  final marks = markProv.childMarks[child.studentId];
                                  if (marks == null) return const Padding(padding: EdgeInsets.all(12), child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                                  if (marks.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('No examination marks published', style: TextStyle(fontSize: 12, color: AppColors.gray500)));
                                  return Column(children: marks.map((m) => ListTile(
                                    dense: true,
                                    leading: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.primary600.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                      child: Text(m.grade ?? '${m.percentage.toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary600)),
                                    ),
                                    title: Text(m.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    subtitle: Text('${m.term}${m.remarks != null ? ' • ${m.remarks}' : ''}', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: Text('${m.score.toInt()}/${m.maxScore.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  )).toList());
                                },
                              ),
                              const Divider(height: 16),
                              // Attendance section
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Row(children: [
                                  Icon(Icons.calendar_today, size: 16, color: AppColors.primary600),
                                  SizedBox(width: 6),
                                  Text('Recent Attendance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                ]),
                              ),
                              if (attendance.isEmpty)
                                const Padding(padding: EdgeInsets.all(16), child: Text('No attendance records', style: TextStyle(color: AppColors.gray500)))
                              else
                                ...attendance.take(10).map((r) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.check_circle, color: AppColors.success500, size: 18),
                                  title: Text(formatDate(r.timestamp), style: const TextStyle(fontSize: 13)),
                                  subtitle: Text(r.cameraLocation, style: const TextStyle(fontSize: 11)),
                                  trailing: Text(formatTime(r.timestamp), style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                                )),
                            ],
                          );
                        },
                        childCount: prov.children.length,
                      )),
          ),
        ]),
      ),
    );
  }
}
