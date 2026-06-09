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
  bool _testingSms = false;
  bool _testingEmail = false;

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
          sliver: SliverList(delegate: SliverChildListDelegate([
            // ── Role info card ──
            if (prov.role != null)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_roleIcon(prov.role!), size: 20, color: AppColors.primary600),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Role: ${prov.role!.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      if (prov.email != null)
                        Text(prov.email!, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                      if (prov.phone != null)
                        Text(prov.phone!, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                    ])),
                    if (prov.smsEnabled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('SMS Ready', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('No Phone', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
                      ),
                  ]),
                ),
              ),

            // ── Notification toggles ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _toggle('In-App Notifications', 'Receive alerts inside the app', Icons.notifications_active, p['in_app'] == true, (v) => _save({...p, 'in_app': v})),
                  const Divider(),
                  _toggle('Email Notifications', 'Get notified via email', Icons.email, p['email'] == true, (v) => _save({...p, 'email': v})),
                  const Divider(),
                  _toggle(
                    'SMS Notifications',
                    prov.smsEnabled ? 'Receive SMS alerts to ${prov.phone}' : 'Add a phone number to enable SMS',
                    Icons.sms,
                    p['sms'] == true,
                    prov.smsEnabled ? (v) => _save({...p, 'sms': v}) : null,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language, size: 20, color: AppColors.gray500),
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

            const SizedBox(height: 16),

            // ── Test notifications ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Test Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Verify your notification channels are working', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testingSms ? null : _sendTestSms,
                        icon: _testingSms
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.sms, size: 16),
                        label: Text(_testingSms ? 'Sending...' : 'Test SMS'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary600,
                          side: const BorderSide(color: AppColors.primary200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testingEmail ? null : _sendTestEmail,
                        icon: _testingEmail
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.email, size: 16),
                        label: Text(_testingEmail ? 'Sending...' : 'Test Email'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary600,
                          side: const BorderSide(color: AppColors.primary200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ])),
        ),
      ]),
    );
  }

  Future<void> _save(Map<String, dynamic> newPrefs) async {
    await context.read<NotificationDbProvider>().savePrefs(newPrefs);
    if (mounted) showSnack(context, 'Preferences saved');
  }

  Future<void> _sendTestSms() async {
    setState(() => _testingSms = true);
    try {
      final result = await context.read<NotificationDbProvider>().sendTest();
      if (mounted) {
        final smsResult = result['results']?['sms'];
        final status = smsResult?['status'] ?? 'unknown';
        if (status == 'sent') {
          showSnack(context, '✅ Test SMS sent to ${result['phone_used']}');
        } else {
          showSnack(context, '⚠️ SMS: ${smsResult?['reason'] ?? smsResult?['error'] ?? status}');
        }
      }
    } catch (e) {
      if (mounted) showSnack(context, '❌ Failed: $e');
    }
    if (mounted) setState(() => _testingSms = false);
  }

  Future<void> _sendTestEmail() async {
    setState(() => _testingEmail = true);
    try {
      final result = await context.read<NotificationDbProvider>().sendTest();
      if (mounted) {
        final emailResult = result['results']?['email'];
        final status = emailResult?['status'] ?? 'unknown';
        if (status == 'sent') {
          showSnack(context, '✅ Test email sent to ${result['email_used']}');
        } else {
          showSnack(context, '⚠️ Email: ${emailResult?['reason'] ?? emailResult?['error'] ?? status}');
        }
      }
    } catch (e) {
      if (mounted) showSnack(context, '❌ Failed: $e');
    }
    if (mounted) setState(() => _testingEmail = false);
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin': return Icons.admin_panel_settings;
      case 'teacher': return Icons.school;
      case 'parent': return Icons.family_restroom;
      default: return Icons.person;
    }
  }

  Widget _toggle(String label, String desc, IconData icon, bool value, ValueChanged<bool>? onChanged) {
    return ListTile(
      leading: Icon(icon, size: 20, color: onChanged != null ? AppColors.primary500 : AppColors.gray300),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary600,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
