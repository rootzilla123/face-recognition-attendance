import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_db_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';

class NotificationDbScreen extends StatefulWidget {
  const NotificationDbScreen({super.key});
  @override
  State<NotificationDbScreen> createState() => _NotificationDbScreenState();
}

class _NotificationDbScreenState extends State<NotificationDbScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationDbProvider>().fetch());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationDbProvider>();
    final filtered = prov.items.where((n) => _search.isEmpty || n.message.toLowerCase().contains(_search.toLowerCase()) || n.title.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationDbProvider>().fetch(),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: GradientHeader(
            title: 'Notifications',
            subtitle: '${prov.unreadCount} unread',
            action: prov.unreadCount > 0 ? TextButton(
              onPressed: () => context.read<NotificationDbProvider>().markAllRead(),
              child: const Text('Mark all read', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ) : null,
          )),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search notifications...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: prov.isLoading
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : filtered.isEmpty
                    ? const SliverToBoxAdapter(child: EmptyState(emoji: '🔔', title: 'No notifications', subtitle: 'You\'re all caught up'))
                    : SliverList(delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final n = filtered[i];
                          return GestureDetector(
                            onTap: () { if (!n.isRead) context.read<NotificationDbProvider>().markRead(n.id); },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: n.isRead ? Colors.white : AppColors.primary50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: n.isRead ? AppColors.gray200 : AppColors.primary100),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: n.isRead ? AppColors.gray100 : AppColors.primary100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(child: Text(_typeEmoji(n.type), style: const TextStyle(fontSize: 18))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 13, color: AppColors.gray900)),
                                  const SizedBox(height: 2),
                                  Text(n.message, style: const TextStyle(fontSize: 12, color: AppColors.gray500), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ])),
                                Column(mainAxisSize: MainAxisSize.min, children: [
                                  Text(formatTime(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                  if (!n.isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: AppColors.primary600, shape: BoxShape.circle)),
                                ]),
                              ]),
                            ),
                          );
                        },
                        childCount: filtered.length,
                      )),
          ),
        ]),
      ),
    );
  }

  String _typeEmoji(String type) {
    switch (type) {
      case 'attendance': return '✅';
      case 'announcement': return '📢';
      case 'alert': return '⚠️';
      default: return '🔔';
    }
  }
}
