import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../core/utils/app_theme.dart';

/// Simple 7-day attendance bar chart — no external chart library needed.
class AttendanceLineChart extends StatelessWidget {
  const AttendanceLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    final records = context.watch<AttendanceProvider>().todayRecords;
    final now = DateTime.now();

    // Count check-ins per day for the last 7 days
    final counts = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return records.where((r) =>
        r.timestamp.year == day.year &&
        r.timestamp.month == day.month &&
        r.timestamp.day == day.day,
      ).length;
    });

    final maxCount = counts.reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Check-ins', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final day = now.subtract(Duration(days: 6 - i));
                  final label = DateFormat('E').format(day);
                  final count = counts[i];
                  final frac = maxCount > 0 ? count / maxCount : 0.0;
                  final isToday = i == 6;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (count > 0)
                            Text('$count', style: const TextStyle(fontSize: 9, color: AppColors.gray500)),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: (frac * 70).clamp(4, 70),
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.primary600 : AppColors.primary100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(label, style: TextStyle(fontSize: 10, color: isToday ? AppColors.primary600 : AppColors.gray400, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
