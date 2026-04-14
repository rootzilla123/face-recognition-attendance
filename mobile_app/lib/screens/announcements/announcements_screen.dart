import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AnnouncementProvider>().fetch());
  }

  void _showCreate() {
    final title = TextEditingController();
    final content = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('New Announcement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: content, maxLines: 4, decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder())),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final ok = await context.read<AnnouncementProvider>().create(title.text.trim(), content.text.trim(), ['student', 'parent', 'teacher', 'admin']);
                if (mounted) showSnack(context, ok ? 'Posted' : 'Failed', error: !ok);
              },
              child: const Text('Post'),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AnnouncementProvider>();
    final auth = context.watch<AuthProvider>();
    final canPost = auth.isAdmin || auth.isTeacher;
    final filtered = prov.items.where((a) => _search.isEmpty || a.title.toLowerCase().contains(_search.toLowerCase()) || a.content.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: RefreshIndicator(
        onRefresh: () => context.read<AnnouncementProvider>().fetch(),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: GradientHeader(
            title: 'Announcements',
            subtitle: 'School-wide announcements',
            action: canPost ? FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary600),
              onPressed: _showCreate,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Post'),
            ) : null,
          )),
          SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search announcements...',
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
                : prov.error != null
                    ? SliverToBoxAdapter(child: ErrorState(message: prov.error!, onRetry: () => context.read<AnnouncementProvider>().fetch()))
                    : filtered.isEmpty
                        ? const SliverToBoxAdapter(child: EmptyState(emoji: '📢', title: 'No announcements', subtitle: 'Check back later'))
                        : SliverList(delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final a = filtered[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gray200), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.gray900))),
                                    if (canPost) IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error500, size: 18), onPressed: () => context.read<AnnouncementProvider>().delete(a.id), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(a.content, style: const TextStyle(color: AppColors.gray600, fontSize: 13, height: 1.4)),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    const Icon(Icons.person_outline, size: 13, color: AppColors.gray400),
                                    const SizedBox(width: 4),
                                    Text(a.authorName, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                    const Spacer(),
                                    Text(formatDate(a.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                                  ]),
                                ]),
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
