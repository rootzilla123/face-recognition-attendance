import 'package:flutter/material.dart';
import '../../core/models/student.dart';
import '../../core/services/parent_service.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';

class FeesScreen extends StatefulWidget {
  final Student child;
  const FeesScreen({super.key, required this.child});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  Map<String, dynamic>? _data;
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
      final data = await ParentService().getChildFees(widget.child.studentId);
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fees = (_data?['fees'] as List?) ?? [];
    final totalOwed = (_data?['total_owed'] as num?)?.toDouble() ?? 0;
    final totalPaid = (_data?['total_paid'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'Fee Statement',
              subtitle: widget.child.fullName,
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())))
          else if (_error != null)
            SliverToBoxAdapter(child: ErrorState(message: _error!, onRetry: _load))
          else ...[
            // Summary cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(children: [
                  Expanded(child: _summaryCard('Total Owed', '\$${totalOwed.toStringAsFixed(2)}',
                      totalOwed > 0 ? AppColors.error500 : AppColors.success500, Icons.receipt_long)),
                  const SizedBox(width: 12),
                  Expanded(child: _summaryCard('Total Paid', '\$${totalPaid.toStringAsFixed(2)}',
                      AppColors.success600, Icons.check_circle_outline)),
                ]),
              ),
            ),
            if (fees.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyState(emoji: '🧾', title: 'No fee records', subtitle: 'No fees have been added yet'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final f = fees[i];
                      final isPaid = f['is_paid'] == true;
                      final amount = (f['amount'] as num).toDouble();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isPaid ? AppColors.success100 : AppColors.error100),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: isPaid ? AppColors.success100 : AppColors.error100,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              isPaid ? Icons.check_circle : Icons.pending_outlined,
                              color: isPaid ? AppColors.success600 : AppColors.error500,
                            ),
                          ),
                          title: Text(f['fee_type']?.toString() ?? '—',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (f['term'] != null)
                              Text(f['term'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                            if (f['due_date'] != null)
                              Text('Due: ${f['due_date'].toString().substring(0, 10)}',
                                  style: TextStyle(fontSize: 11, color: isPaid ? AppColors.gray400 : AppColors.error500)),
                          ]),
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('\$${amount.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15,
                                    color: isPaid ? AppColors.success600 : AppColors.error500)),
                            Text(isPaid ? 'PAID' : 'UNPAID',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                    color: isPaid ? AppColors.success600 : AppColors.error500)),
                          ]),
                        ),
                      );
                    },
                    childCount: fees.length,
                  ),
                ),
              ),
          ],
        ]),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
      ]),
    );
  }
}
