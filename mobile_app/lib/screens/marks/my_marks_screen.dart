import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/mark_provider.dart';
import '../../core/models/student.dart';
import '../../core/services/student_service.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';

class MyMarksScreen extends StatefulWidget {
  const MyMarksScreen({super.key});

  @override
  State<MyMarksScreen> createState() => _MyMarksScreenState();
}

class _MyMarksScreenState extends State<MyMarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarkProvider>().fetchMyMarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MarkProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: () => prov.fetchMyMarks(),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: GradientHeader(
            title: 'My Marks',
            subtitle: 'View your examination results',
            action: IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              onPressed: () async {
                if (prov.marks.isEmpty) { showSnack(context, 'No marks to export', error: true); return; }
                showDialog(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text('Preparing Report...')])));
                try {
                  final student = await StudentService().getMyProfile();
                  await ExportService().exportAndShareMarksPdf(prov.marks, student);
                } catch (e) {
                  if (mounted) showSnack(context, 'Error: $e', error: true);
                } finally { if (mounted) Navigator.pop(context); }
              },
              tooltip: 'Export Report Card',
            ),
          )),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: prov.isLoading && prov.marks.isEmpty
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : prov.error != null
                    ? SliverToBoxAdapter(child: ErrorState(message: prov.error!, onRetry: () => prov.fetchMyMarks()))
                    : prov.marks.isEmpty
                        ? const SliverToBoxAdapter(child: EmptyState(
                            emoji: '📝',
                            title: 'No marks published',
                            subtitle: 'Your marks will appear here once published by your teacher',
                          ))
                        : SliverList(delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final m = prov.marks[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                                  border: Border.all(color: AppColors.gray100),
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(m.subject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                                      Text(m.term, style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                    ])),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(12)),
                                      child: Text(m.grade ?? '${m.percentage.toInt()}%', style: const TextStyle(color: AppColors.primary700, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                  ]),
                                  const SizedBox(height: 20),
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    const Text('Score', style: TextStyle(color: AppColors.gray500, fontSize: 13, fontWeight: FontWeight.w500)),
                                    Text('${m.score.toInt()} / ${m.maxScore.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900)),
                                  ]),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: m.percentage / 100,
                                      minHeight: 8,
                                      backgroundColor: AppColors.gray100,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.primary600),
                                    ),
                                  ),
                                  if (m.remarks != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.gray100)),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Text('REMARKS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.gray400, letterSpacing: 1)),
                                        const SizedBox(height: 4),
                                        Text(m.remarks!, style: const TextStyle(fontSize: 13, color: AppColors.gray700, fontStyle: FontStyle.italic)),
                                      ]),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text('Recorded on ${DateFormat('MMM dd, yyyy').format(m.createdAt)}', style: const TextStyle(fontSize: 10, color: AppColors.gray400)),
                                  ),
                                ]),
                              );
                            },
                            childCount: prov.marks.length,
                          )),
          ),
        ]),
      ),
    );
  }
}
