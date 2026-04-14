import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../providers/websocket_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/common/gradient_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _api = ApiClient();
  List<dynamic> _inApp = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadInApp();
  }

  Future<void> _loadInApp() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/notifications');
      setState(() => _inApp = List.from(data));
    } catch (_) {}
    finally { setState(() => _loading = false); }
  }

  Future<void> _markRead(String id) async {
    try {
      await _api.post('/notifications/$id/read', {});
      setState(() { _inApp = _inApp.map((n) => n['id'] == id ? {...n, 'is_read': true} : n).toList(); });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await _api.post('/notifications/read-all', {});
      setState(() { _inApp = _inApp.map((n) => {...n, 'is_read': true}).toList(); });
    } catch (_) {}
  }

  String _fmt(String? ts) {
    if (ts == null) return '';
    try { final d = DateTime.parse(ts); return '${d.day}/${d.month} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}'; } catch (_) { return ts; }
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketProvider>();
    final unread = _inApp.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(children: [
        GradientHeader(
          title: 'Notifications',
          subtitle: '$unread unread',
          action: unread > 0 ? TextButton(onPressed: _markAllRead, child: const Text('Mark all read', style: TextStyle(color: Colors.white70))) : null,
        ),
        TabBar(
          controller: _tabs,
          labelColor: AppColors.primary600,
          unselectedLabelColor: AppColors.gray400,
          indicatorColor: AppColors.primary600,
          tabs: [
            Tab(text: 'In-App${unread > 0 ? ' ($unread)' : ''}'),
            const Tab(text: 'Live Events'),
          ],
        ),
        Expanded(child: TabBarView(controller: _tabs, children: [
          // In-app notifications
          RefreshIndicator(
            onRefresh: _loadInApp,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _inApp.isEmpty
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('🔔', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 8),
                        Text('No notifications yet', style: TextStyle(color: AppColors.gray400)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _inApp.length,
                        itemBuilder: (ctx, i) {
                          final n = _inApp[i];
                          final isRead = n['is_read'] == true;
                          return GestureDetector(
                            onTap: () { if (!isRead) _markRead(n['id']); },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isRead ? Colors.white : AppColors.primary50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isRead ? AppColors.gray100 : AppColors.primary100),
                              ),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 5, right: 10),
                                  decoration: BoxDecoration(color: isRead ? AppColors.gray300 : AppColors.primary500, shape: BoxShape.circle)),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  if (n['title'] != null) Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(n['message'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                                  const SizedBox(height: 4),
                                  Text(_fmt(n['created_at']), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                ])),
                              ]),
                            ),
                          );
                        },
                      ),
          ),

          // Live WebSocket events
          ws.recentDetections.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('📡', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text('No live events yet', style: TextStyle(color: AppColors.gray400)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: ws.recentDetections.length,
                  itemBuilder: (ctx, i) {
                    final d = ws.recentDetections[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFD1FAE5), child: Text('✓', style: TextStyle(color: Color(0xFF059669)))),
                        title: Text('Student #${d['student_id'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(d['camera_location']?.toString().replaceAll('_', ' ') ?? '—'),
                        trailing: Text(_fmt(d['timestamp']?.toString()), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                      ),
                    );
                  },
                ),
        ])),
      ]),
    );
  }

  @override
  void dispose() { _tabs.dispose(); _api.dispose(); super.dispose(); }
}
