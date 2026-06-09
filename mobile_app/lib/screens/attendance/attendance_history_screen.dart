import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/models/attendance.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/offline_banner.dart';
import '../../core/services/reports_service.dart';
import '../../core/services/parent_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String _selectedFilter = 'week'; // week, month, all
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<AttendanceRecord> _records = [];
  String? _error;
  final ReportsService _reportsService = ReportsService();
  final ParentService _parentService = ParentService();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

      List<AttendanceRecord> records;
      if (auth.user?.role == 'student') {
        records = await _reportsService.getMyAttendance();
      } else if (auth.user?.role == 'parent') {
        final children = await _parentService.getChildren();
        if (children.isEmpty) {
          records = [];
        } else {
          records = await _reportsService.getChildAttendance(children.first.id);
        }
      } else {
        records = await _reportsService.getByDateRange(startStr, endStr);
      }

      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load attendance records';
        _isLoading = false;
      });
    }
  }

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      final now = DateTime.now();
      switch (filter) {
        case 'week':
          _startDate = now.subtract(const Duration(days: 7));
          _endDate = now;
          break;
        case 'month':
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
          break;
        case 'all':
          _startDate = now.subtract(const Duration(days: 365));
          _endDate = now;
          break;
      }
    });
    _loadAttendance();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary500,
              surface: AppColors.gray800,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 'custom';
      });
      _loadAttendance();
    }
  }

  Map<String, dynamic> _calculateStats() {
    if (_records.isEmpty) {
      return {
        'present': 0,
        'absent': 0,
        'rate': 0.0,
      };
    }

    final present = _records.where((r) => r.confidenceScore > 0).length;
    final total = _records.length;
    return {
      'present': present,
      'absent': total - present,
      'rate': total > 0 ? (present / total * 100) : 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'Attendance History',
            subtitle: auth.user?.role == 'student'
                ? 'View your attendance records'
                : auth.user?.role == 'parent'
                    ? 'View your child\'s attendance'
                    : 'View attendance records',
          ),
          const OfflineBanner(),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'This Week',
                    isSelected: _selectedFilter == 'week',
                    onTap: () => _setFilter('week'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'This Month',
                    isSelected: _selectedFilter == 'month',
                    onTap: () => _setFilter('month'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'All Time',
                    isSelected: _selectedFilter == 'all',
                    onTap: () => _setFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Custom Range',
                    isSelected: _selectedFilter == 'custom',
                    onTap: _selectDateRange,
                  ),
                ],
              ),
            ),
          ),
          // Stats cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Present',
                    value: stats['present'].toString(),
                    color: AppColors.success500,
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Absent',
                    value: stats['absent'].toString(),
                    color: AppColors.error500,
                    icon: Icons.cancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Rate',
                    value: '${stats['rate'].toStringAsFixed(1)}%',
                    color: AppColors.primary500,
                    icon: Icons.trending_up,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Attendance list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAttendance,
              color: AppColors.primary500,
              backgroundColor: Colors.white,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _records.isEmpty
                          ? _buildEmptyState()
                          : _buildAttendanceList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error500),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.gray900, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gray700),
            ),
            child: const Icon(
              Icons.calendar_today,
              size: 48,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Attendance Records',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No records found for the selected date range',
            style: TextStyle(
              color: AppColors.gray500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAttendance,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Group records by date
    final groupedRecords = <String, List<AttendanceRecord>>{};
    for (final record in _records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.timestamp);
      groupedRecords.putIfAbsent(dateKey, () => []);
      groupedRecords[dateKey]!.add(record);
    }

    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dateRecords = groupedRecords[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(date),
                style: const TextStyle(
                  color: AppColors.gray400,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...dateRecords.map((record) => _AttendanceRecordCard(
              record: record,
              studentName: context.read<AttendanceProvider>().nameFor(record.studentId),
            )),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary500 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary500 : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.gray400,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.gray900,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.gray400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRecordCard extends StatelessWidget {
  final AttendanceRecord record;
  final String studentName;

  const _AttendanceRecordCard({
    required this.record,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = record.confidenceScore > 0;
    final time = DateFormat('h:mm a').format(record.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPresent ? AppColors.success500.withValues(alpha: 0.2) : AppColors.error500.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPresent ? Icons.check_circle : Icons.cancel,
              color: isPresent ? AppColors.success500 : AppColors.error500,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    color: AppColors.gray900,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.cameraLocation.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: AppColors.gray400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPresent ? AppColors.success500.withValues(alpha: 0.2) : AppColors.error500.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPresent ? 'PRESENT' : 'ABSENT',
                  style: TextStyle(
                    color: isPresent ? AppColors.success500 : AppColors.error500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
