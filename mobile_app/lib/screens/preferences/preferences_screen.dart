import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_db_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/common/gradient_header.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationDbProvider>().loadPrefs());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationDbProvider>();
    final p = prov.prefs;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: GradientHeader(title: 'Notification Preferences', subtitle: 'Choose how you want to be notified')),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _toggle('In-App Notifications', 'Receive alerts inside the app', p['in_app'] == true, (v) => _save({...p, 'in_app': v})),
                  const Divider(),
                  _toggle('Email Notifications', 'Get notified via email', p['email'] == true, (v) => _save({...p, 'email': v})),
                  const Divider(),
                  _toggle('SMS Notifications', 'Receive SMS alerts', p['sms'] == true, (v) => _save({...p, 'sms': v})),
                  const Divider(),
                  ListTile(
                    title: const Text('Language', style: TextStyle(fontWeight: FontWeight.w500)),
                    trailing: DropdownButton<String>(
                      value: p['language']?.toString() ?? 'en',
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'sw', child: Text('Swahili')),
                      ],
                      onChanged: (v) => _save({...p, 'language': v}),
                      underline: const SizedBox(),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _save(Map<String, dynamic> newPrefs) async {
    await context.read<NotificationDbProvider>().savePrefs(newPrefs);
    if (mounted) showSnack(context, 'Preferences saved');
  }

  Widget _toggle(String label, String desc, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary600),
      contentPadding: EdgeInsets.zero,
    );
  }
}
