import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/camera_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parent_provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/attendance/stats_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isStudent) return _StudentHome();
    if (auth.isParent) return _ParentHome();
    return _AdminTeacherHome();
  }
}

// ── Admin / Teacher Home ─────────────────────────────────────────────────────
class _AdminTeacherHome extends StatefulWidget {
  @override
  State<_AdminTeacherHome> createState() => _AdminTeacherHomeState();
}

class _AdminTeacherHomeState extends State<_AdminTeacherHome> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    if (!mounted) return;
    await Future.wait([
      context.read<AttendanceProvider>().fetchToday(),
      context.read<CameraProvider>().fetchCameras(),
    ]);
  }

  Color _rateColor(double pct) {
    if (pct >= 90) return AppColors.success600;
    if (pct >= 75) return AppColors.orange500;
    return AppColors.error500;
  }

  @override
  Widget build(BuildContext context) {
    final att = context.watch<AttendanceProvider>();
    final cam = context.watch<CameraProvider>();
    final ws = context.watch<WebSocketProvider>();
    final auth = context.watch<AuthProvider>();
    final stats = att.stats;
    final activeCams = cam.cameras.where((c) => c.isActive).length;
    final recent = att.todayRecords.take(5).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: GradientHeader(
          title: 'Welcome Back! 👋',
          subtitle: auth.user?.fullName ?? "Here's what's happening today",
          showWsStatus: true,
          wsConnected: ws.isConnected,
        )),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: att.error != null && att.todayRecords.isEmpty
                ? ErrorState(message: att.error!, onRetry: _load)
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GridView.count(
                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.55,
                      children: [
                        StatsCard.blue(label: 'Total Students', value: stats?.totalStudents.toString() ?? '—', icon: '👥', subtitle: 'Enrolled'),
                        StatsCard.green(label: 'Present Today', value: stats?.presentStudents.toString() ?? '—', icon: '✅', subtitle: 'Checked in'),
                        StatsCard.purple(label: 'Active Cameras', value: activeCams.toString(), icon: '📹', subtitle: 'Operational'),
                        StatsCard.orange(label: 'Attendance Rate', value: stats != null ? '${stats.attendancePercentage.toStringAsFixed(1)}%' : '—', icon: '📊',
                          subtitle: stats != null ? (stats.attendancePercentage >= 90 ? 'Excellent!' : stats.attendancePercentage >= 75 ? 'Good' : 'Needs attention') : '—'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))]),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Recent Check-ins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                              Text('Latest student arrivals', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                            ]),
                            if (att.isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          ]),
                        ),
                        const Divider(height: 1),
                        if (recent.isEmpty)
                          const EmptyState(emoji: '📭', title: 'No check-ins yet today', subtitle: 'Check-ins will appear here as students arrive')
                        else
                          ...recent.asMap().entries.map((e) {
                            final r = e.value; final i = e.key;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.success50, AppColors.primary50]), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success100)),
                              child: Row(children: [
                                Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.success500, AppColors.primary500]), borderRadius: BorderRadius.circular(22)),
                                  child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(att.nameFor(r.studentId), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900)),
                                  Text(r.cameraLocation, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                                  Text(formatTime(r.timestamp), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                  Text(formatPercent(r.confidenceScore), style: TextStyle(fontSize: 11, color: _rateColor(r.confidenceScore * 100), fontWeight: FontWeight.w600)),
                                ]),
                              ]),
                            );
                          }),
                        const SizedBox(height: 8),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: ws.isConnected ? const Color(0xFF4ADE80) : Colors.redAccent, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          const Text('System Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ]),
                        const SizedBox(height: 12),
                        _row('Face Recognition', 'Online'),
                        _row('Camera Streams', activeCams > 0 ? 'Active ($activeCams)' : 'No cameras'),
                        _row('WebSocket', ws.isConnected ? 'Connected' : 'Reconnecting...'),
                        _row('Present Today', '${stats?.presentStudents ?? 0} / ${stats?.totalStudents ?? 0}'),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}

// ── Student Home ─────────────────────────────────────────────────────────────
class _StudentHome extends StatefulWidget {
  @override
  State<_StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<_StudentHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isStudent) {
        // Students use dedicated /attendance/my endpoint
        context.read<AttendanceProvider>().fetchMyAttendance();
      } else {
        context.read<AttendanceProvider>().fetchToday();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final att = context.watch<AttendanceProvider>();
    final auth = context.watch<AuthProvider>();
    // Filter to only this student's records
    final myRecords = att.todayRecords.where((r) => r.studentId == auth.user?.id || att.nameFor(r.studentId) == auth.user?.fullName).toList();

    return RefreshIndicator(
      onRefresh: () => context.read<AttendanceProvider>().fetchToday(),
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: GradientHeader(title: 'My Attendance', subtitle: auth.user?.fullName ?? '')),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(child: Column(children: [
            // Today summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)]),
              child: Row(children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: myRecords.isNotEmpty ? AppColors.success100 : AppColors.error100, borderRadius: BorderRadius.circular(28)),
                  child: Center(child: Text(myRecords.isNotEmpty ? '✅' : '❌', style: const TextStyle(fontSize: 26)))),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(myRecords.isNotEmpty ? 'Present Today' : 'Not Yet Checked In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                  Text(myRecords.isNotEmpty ? 'Checked in at ${formatTime(myRecords.first.timestamp)}' : 'No check-in recorded today', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            if (myRecords.isNotEmpty) ...[
              const Align(alignment: Alignment.centerLeft, child: Text("Today's Records", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.gray900))),
              const SizedBox(height: 8),
              ...myRecords.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.success100)),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.success500, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r.cameraLocation, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text(formatTime(r.timestamp), style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(formatPercent(r.confidenceScore), style: const TextStyle(color: AppColors.success600, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              )),
            ] else
              const EmptyState(emoji: '📋', title: 'No records today', subtitle: 'Your attendance will appear here once you check in'),
          ])),
        ),
      ]),
    );
  }
}

// ── Parent Home ──────────────────────────────────────────────────────────────
class _ParentHome extends StatefulWidget {
  @override
  State<_ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<_ParentHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ParentProvider>().fetchChildren());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ParentProvider>();
    final auth = context.watch<AuthProvider>();

    return RefreshIndicator(
      onRefresh: () => context.read<ParentProvider>().fetchChildren(),
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: GradientHeader(title: 'Welcome Back! 👋', subtitle: auth.user?.fullName ?? 'Parent Dashboard')),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: prov.children.isEmpty
              ? const SliverToBoxAdapter(child: EmptyState(emoji: '👨‍👧', title: 'No children linked', subtitle: 'Go to Children tab to link your child'))
              : SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final child = prov.children[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                      child: Row(children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: AppColors.blueGradient), borderRadius: BorderRadius.circular(24)),
                          child: Center(child: Text(child.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.gray900)),
                          Text('${child.gradeLevel}${child.section != null ? ' • ${child.section}' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                        ])),
                        const Icon(Icons.chevron_right, color: AppColors.gray400),
                      ]),
                    );
                  },
                  childCount: prov.children.length,
                )),
        ),
      ]),
    );
  }
}
