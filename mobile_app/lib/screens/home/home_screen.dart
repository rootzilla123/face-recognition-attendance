import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/camera_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parent_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/hover_card.dart';
import '../../widgets/attendance/stats_card.dart';
import '../shell.dart';
import '../attendance/clip_player_screen.dart';

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
  Map<String, dynamic>? _liveAlert;
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() { _timer?.cancel(); _alertTimer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    if (!mounted) return;
    await Future.wait([
      context.read<AttendanceProvider>().fetchToday(),
      context.read<CameraProvider>().fetchCameras(),
    ]);
  }

  int _lastDetectionCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = context.watch<WebSocketProvider>();
    final att = context.read<AttendanceProvider>();
    
    if (ws.recentDetections.length > _lastDetectionCount) {
      _lastDetectionCount = ws.recentDetections.length;
      final latest = ws.recentDetections.first;
      
      // Map ID to Name if possible
      final studentId = latest['student_id']?.toString() ?? '';
      final studentName = latest['student_name'] ?? att.nameFor(studentId);
      
      setState(() => _liveAlert = {
        ...latest,
        'student_display_name': studentName,
      });
      
      _alertTimer?.cancel();
      _alertTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) setState(() => _liveAlert = null);
      });
    }
  }

  void _triggerDemo() {
    final att = context.read<AttendanceProvider>();
    // If no records, we can't easily find a name, so we use a fallback
    final demoName = att.todayRecords.isNotEmpty 
        ? att.nameFor(att.todayRecords.first.studentId)
        : "Alex Johnson";
    
    setState(() => _liveAlert = {
      'student_id': 'demo_123',
      'student_display_name': demoName,
      'camera_location': 'Main Gate',
      'confidence': 0.987,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _alertTimer?.cancel();
    _alertTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _liveAlert = null);
    });
    
    // Haptic feedback for the "wow" factor
    HapticFeedback.heavyImpact();
  }

  Color _rateColor(double pct) {
    if (pct >= 90) return AppColors.success600;
    if (pct >= 75) return AppColors.orange500;
    return AppColors.error500;
  }

  void _showManualAttendance(BuildContext context) {
    final studentCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Manual Entry');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Manual Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Mark a student present manually', style: TextStyle(fontSize: 13, color: AppColors.gray500)),
          const SizedBox(height: 16),
          TextField(
            controller: studentCtrl,
            decoration: const InputDecoration(labelText: 'Student ID', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locationCtrl,
            decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FilledButton(
              onPressed: () async {
                if (studentCtrl.text.trim().isEmpty) return;
                Navigator.pop(context);
                final prov = context.read<AttendanceProvider>();
                final messenger = ScaffoldMessenger.of(context);
                await prov.createManualAttendance(
                  studentCtrl.text.trim(),
                  locationCtrl.text.trim().isEmpty ? 'Manual Entry' : locationCtrl.text.trim(),
                );
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('Attendance marked')));
              },
              child: const Text('Mark Present'),
            )),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            )),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
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
      child: Stack(
        children: [
          CustomScrollView(slivers: [
        SliverToBoxAdapter(child: GestureDetector(
          onLongPress: _triggerDemo, // Secret pitch trigger!
          child: GradientHeader(
            title: 'Welcome Back! 👋',
            subtitle: auth.user?.fullName ?? "Here's what's happening today",
            showWsStatus: true,
            wsConnected: ws.isConnected,
            action: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        )),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: att.error != null && att.todayRecords.isEmpty
                ? ErrorState(message: att.error!, onRetry: _load)
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    GridView.count(
                      crossAxisCount: Responsive.gridColumns(context),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: Responsive.spacing(context, mobile: 10, desktop: 20),
                      mainAxisSpacing: Responsive.spacing(context, mobile: 10, desktop: 20),
                      childAspectRatio: Responsive.isDesktop(context) ? 1.8 : 1.55,
                      children: [
                        HoverCard(child: StatsCard.blue(label: 'Total Students', value: stats?.totalStudents.toString() ?? '—', icon: '👥', subtitle: 'Enrolled')),
                        HoverCard(child: StatsCard.green(label: 'Present Today', value: stats?.presentStudents.toString() ?? '—', icon: '✅', subtitle: 'Checked in')),
                        HoverCard(child: StatsCard.purple(label: 'Active Cameras', value: activeCams.toString(), icon: '📹', subtitle: 'Operational')),
                        HoverCard(child: StatsCard.orange(label: 'Attendance Rate', value: stats != null ? '${stats.attendancePercentage.toStringAsFixed(1)}%' : '—', icon: '📊',
                          subtitle: stats != null ? (stats.attendancePercentage >= 90 ? 'Excellent!' : stats.attendancePercentage >= 75 ? 'Good' : 'Needs attention') : '—')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900, letterSpacing: -0.5)),
                    const SizedBox(height: 12),
                    _QuickActionsGrid(),
                    const SizedBox(height: 24),
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
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              if (att.isLoading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: () => _showManualAttendance(context),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Manual', style: TextStyle(fontSize: 12)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.secondary600,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ]),
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
                                if (r.clipPath != null) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ClipPlayerScreen(
                                        attendanceId: r.id,
                                        studentName: att.nameFor(r.studentId),
                                        timestamp: r.timestamp,
                                      ),
                                    )),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: AppColors.primary500, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
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
          // Live detection banner
          if (_liveAlert != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success500, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_liveAlert!['student_display_name'] ?? 'Unknown Student'} · ${_liveAlert!['camera_location']}',
                        style: const TextStyle(color: AppColors.gray900, fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${((_liveAlert!['confidence'] as num) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: AppColors.success600, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _liveAlert = null),
                      icon: const Icon(Icons.close, color: AppColors.gray500, size: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
    // `/attendance/my` already scopes records to the logged-in student.
    final myRecords = att.todayRecords;

    return RefreshIndicator(
      onRefresh: () => context.read<AttendanceProvider>().fetchMyAttendance(),
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: GradientHeader(
          title: 'My Attendance', 
          subtitle: auth.user?.fullName ?? '',
          action: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        )),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: Column(children: [
            const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            _QuickActionsGrid(),
            const SizedBox(height: 24),
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
          ]).toSliver(),
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
        SliverToBoxAdapter(child: GradientHeader(
          title: 'Welcome Back! 👋',
          subtitle: auth.user?.fullName ?? 'Parent Dashboard',
          action: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        )),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              _QuickActionsGrid(),
              const SizedBox(height: 24),
              const Text('My Children', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.gray900, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              if (prov.children.isEmpty)
                const EmptyState(emoji: '👨‍👧', title: 'No children linked', subtitle: 'Go to Children tab to link your child')
              else
                ...prov.children.map((child) => Container(
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
                )),
            ],
          ).toSliver(),
        ),
      ]),
    );
  }
}

extension on Widget {
  SliverToBoxAdapter toSliver() => SliverToBoxAdapter(child: this);
}

// ── Shared Components ────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final List<_ActionItem> actions = [];

    actions.add(_ActionItem('Dashboard', '📊', 'dashboard', AppColors.primary500));
    
    if (auth.isAdmin || auth.isTeacher) {
      actions.add(_ActionItem('Cameras', '📹', 'cameras', AppColors.secondary500));
      actions.add(_ActionItem('Students', '👥', 'students', AppColors.indigo500));
    }
    
    if (auth.isParent) {
      actions.add(_ActionItem('My Children', '👨‍👧', 'children', AppColors.indigo500));
    }

    actions.add(_ActionItem('News', '📢', 'announcements', AppColors.orange500));
    actions.add(_ActionItem('Messages', '💬', 'messages', AppColors.secondary500));
    actions.add(_ActionItem('Inbox', '📬', 'notifs', AppColors.primary600));
    actions.add(_ActionItem('Alerts', '🔔', 'alerts', AppColors.error500));

    if (auth.isAdmin || auth.isTeacher) {
      actions.add(_ActionItem('Reports', '📄', 'reports', AppColors.secondary600));
    }

    if (auth.isAdmin) {
      actions.add(_ActionItem('Admin', '🛡️', 'admin', AppColors.gray700));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final action = actions[i];
        return _QuickActionItem(
          icon: action.icon,
          label: action.label,
          color: action.color,
          onTap: () {
            // This is a bit tricky because we need the list of tabs to find the index
            // But AppShell's screen list is role-dependent.
            // We'll use a hack: navigate via a "More" drawer logic or just use a provider
            // that AppShell listens to.
            final nav = context.read<NavigationProvider>();
            // Since we don't have the full screen list here, 
            // we'll rely on AppShell defining screens similarly.
            // A better way is to move _buildScreens to a shared location.
            // For now, let's assume NavigationProvider.setTabByKey handles it by rebuilding the list.
            
            // We need to pass the list of screens as defined in AppShell
            // I'll create a static method in AppShell to get the list
            nav.setTabByKey(action.key, AppShell.buildTabItems(auth));
          },
        );
      },
    );
  }
}

class _ActionItem {
  final String label, icon, key;
  final Color color;
  _ActionItem(this.label, this.icon, this.key, this.color);
}

class _QuickActionItem extends StatelessWidget {
  final String icon, label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 8),
          Text(label, 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray700),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
