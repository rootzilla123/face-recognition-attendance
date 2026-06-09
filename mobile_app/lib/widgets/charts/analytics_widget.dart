import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/app_theme.dart';

class AnalyticsWidget extends StatefulWidget {
  const AnalyticsWidget({super.key});
  @override
  State<AnalyticsWidget> createState() => _AnalyticsWidgetState();
}

class _AnalyticsWidgetState extends State<AnalyticsWidget> {
  List<dynamic> _trend = [];
  List<dynamic> _late = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient().get('/reports/weekly-trend'),
        ApiClient().get('/reports/late-arrivals'),
      ]);
      setState(() {
        _trend = (results[0] as Map)['trend'] as List? ?? [];
        _late = (results[1] as Map)['records'] as List? ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final maxRate = _trend.isEmpty ? 100.0 : _trend.map((d) => (d['rate'] as num).toDouble()).reduce((a, b) => a > b ? a : b);

    return Column(children: [
      // 7-day trend chart
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('7-Day Attendance Trend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: _trend.isEmpty
                  ? const Center(child: Text('No data', style: TextStyle(color: AppColors.gray400)))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _trend.asMap().entries.map((e) {
                        final d = e.value;
                        final rate = (d['rate'] as num).toDouble();
                        final frac = maxRate > 0 ? rate / maxRate : 0.0;
                        final isToday = e.key == _trend.length - 1;
                        final color = rate >= 90 ? AppColors.success500 : rate >= 75 ? AppColors.orange500 : AppColors.error500;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                              Text('${rate.toStringAsFixed(0)}%', style: TextStyle(fontSize: 9, color: isToday ? color : AppColors.gray400, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                height: (frac * 70).clamp(4, 70),
                                decoration: BoxDecoration(
                                  color: isToday ? color : AppColors.primary100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(d['day'] ?? '', style: TextStyle(fontSize: 10, color: isToday ? color : AppColors.gray400, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),

      // Late arrivals
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Late Arrivals Today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _late.isEmpty ? AppColors.success100 : AppColors.warning50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${_late.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _late.isEmpty ? AppColors.success600 : AppColors.orange700)),
              ),
            ]),
            const SizedBox(height: 10),
            if (_late.isEmpty)
              const Text('🎉 No late arrivals today!', style: TextStyle(color: AppColors.success600, fontSize: 13))
            else
              ..._late.take(5).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.warning50, borderRadius: BorderRadius.circular(18)),
                    child: const Center(child: Text('⏰', style: TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(s['grade_level'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(s['arrival_time'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.orange700, fontSize: 13)),
                    Text('+${s['minutes_late']} min', style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                  ]),
                ]),
              )),
          ]),
        ),
      ),
    ]);
  }
}
