import 'package:flutter/material.dart';
import '../../core/services/message_service.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _service = MessageService();
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getConversations();
      setState(() => _conversations = data);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _showNewMessage() async {
    try {
      final users = await ApiClient().get('/messages/users/searchable') as List;
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Start a conversation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...users.map((u) => ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary100,
                child: Text(u['full_name'][0].toUpperCase(), style: const TextStyle(color: AppColors.primary700)),
              ),
              title: Text(u['full_name']),
              subtitle: Text(u['role']),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatScreen(conversationId: u['id'], recipientName: u['full_name']),
                ));
              },
            )),
          ],
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to load users: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _conversations.where((c) =>
        _search.isEmpty ||
        (c['other_user']?['full_name']?.toString().toLowerCase().contains(_search.toLowerCase()) ?? false) ||
        (c['last_message']?['content']?.toString().toLowerCase().contains(_search.toLowerCase()) ?? false)
    ).toList();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              title: 'Messages',
              subtitle: '${_conversations.length} conversations',
              action: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary600),
                onPressed: _showNewMessage,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('New'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
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
            sliver: _loading
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                : _error != null
                    ? SliverToBoxAdapter(child: ErrorState(message: _error!, onRetry: _load))
                    : filtered.isEmpty
                        ? const SliverToBoxAdapter(child: EmptyState(emoji: '💬', title: 'No conversations', subtitle: 'Start a new chat to see conversations here'))
                        : SliverList(delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final convo = filtered[i];
                              final otherUser = convo['other_user'];
                              final lastMessage = convo['last_message'];
                              final unreadCount = convo['unread_count'] ?? 0;
                              final ts = lastMessage?['created_at'];
                              final timeStr = ts != null
                                  ? formatTime(DateTime.tryParse(ts.toString()) ?? DateTime.now())
                                  : '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gray200),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                                ),
                                child: ListTile(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId: convo['id'],
                                      recipientName: otherUser?['full_name'] ?? 'Unknown',
                                    ),
                                  )),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary100,
                                    child: Text(
                                      otherUser?['full_name']?[0].toUpperCase() ?? '?',
                                      style: const TextStyle(color: AppColors.primary700, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(otherUser?['full_name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    lastMessage?['content'] ?? 'No messages yet',
                                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Column(mainAxisSize: MainAxisSize.min, children: [
                                    Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                    if (unreadCount > 0)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: AppColors.primary600, shape: BoxShape.circle),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                      ),
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
}
