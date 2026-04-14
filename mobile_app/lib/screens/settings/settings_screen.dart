import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/camera_provider.dart';
import '../../core/models/camera.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/server_config.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../core/services/health_service.dart';
import '../../widgets/common/gradient_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _serverUrlCtrl;
  late TextEditingController _pbUrlCtrl;
  late TabController _tabCtrl;
  bool _testingUrl = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _serverUrlCtrl = TextEditingController(text: ServerConfig.baseUrl);
    _pbUrlCtrl = TextEditingController(text: ServerConfig.pbUrl);
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<CameraProvider>().fetchCameras());
  }

  @override
  void dispose() {
    _serverUrlCtrl.dispose();
    _pbUrlCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }


  Future<void> _savePbUrl() async {
    final url = _pbUrlCtrl.text.trim();
    if (url.isEmpty) return;
    await ServerConfig.savePbUrl(url);
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PocketBase URL saved'))); }
  }

  Future<void> _saveAndTestUrl() async {
    final url = _serverUrlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _testingUrl = true; _testResult = null; });
    await ServerConfig.save(url);
    final ok = await HealthService.check();
    setState(() {
      _testingUrl = false;
      _testOk = ok;
      _testResult = ok ? '✓ Connected to server' : '✗ Cannot reach server — check IP and make sure backend is running';
    });
  }

  void _showEditDialog(Camera cam) {
    final nameCtrl = TextEditingController(text: cam.name);
    final locationCtrl = TextEditingController(text: cam.location);
    final frCtrl = TextEditingController(text: cam.frameRate.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Camera'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: frCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Frame Rate (fps)', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<CameraProvider>().updateCamera(cam.id, {
                'name': nameCtrl.text.trim(),
                'location': locationCtrl.text.trim(),
                'frame_rate': int.tryParse(frCtrl.text) ?? cam.frameRate,
              });
              if (mounted) showSnack(context, ok ? 'Camera updated' : 'Failed', error: !ok);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Camera cam) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Camera?'),
        content: Text('Remove "${cam.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<CameraProvider>().deleteCamera(cam.id);
              if (mounted) showSnack(context, ok ? 'Camera deleted' : 'Failed', error: !ok);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CameraProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverToBoxAdapter(child: GradientHeader(title: 'Settings', subtitle: 'Configuration and system settings')),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.primary600,
                unselectedLabelColor: AppColors.gray500,
                indicatorColor: AppColors.primary600,
                tabs: const [
                  Tab(text: '🖥️  Server'),
                  Tab(text: '📹  Cameras'),
                  Tab(text: 'ℹ️  About'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── SERVER TAB ──────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Server Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Override the default server URL (advanced)', style: TextStyle(color: AppColors.gray500, fontSize: 12)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _serverUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'API Server URL',
                        hintText: 'https://api.shadomfacepro.duckdns.org',
                        prefixIcon: Icon(Icons.dns_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _testingUrl ? null : _saveAndTestUrl,
                        icon: _testingUrl
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.wifi_find_outlined),
                        label: Text(_testingUrl ? 'Testing...' : 'Save & Test Connection'),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text('PocketBase URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Auth server address', style: TextStyle(color: AppColors.gray500, fontSize: 12)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pbUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'PocketBase URL',
                        hintText: 'https://pb.shadomfacepro.duckdns.org',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _savePbUrl,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save PocketBase URL'),
                      ),
                    ),
                    if (_testResult != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _testOk ? AppColors.success50 : AppColors.error50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _testOk ? AppColors.success500 : AppColors.error500),
                        ),
                        child: Text(_testResult!, style: TextStyle(color: _testOk ? AppColors.success700 : AppColors.error700, fontSize: 13)),
                      ),
                    ],
                  ]),
                ),
              ),
            ),

            // ── CAMERAS TAB ─────────────────────────────────────
            RefreshIndicator(
              onRefresh: () => context.read<CameraProvider>().fetchCameras(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Camera Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (prov.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (prov.cameras.isEmpty)
                        const Text('No cameras configured', style: TextStyle(color: Colors.grey))
                      else
                        ...prov.cameras.map((cam) => ListTile(
                          leading: Icon(Icons.videocam, color: cam.isActive ? Colors.green : Colors.grey),
                          title: Text(cam.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          subtitle: Text('${cam.location} • ${cam.protocol.toUpperCase()} • ${cam.frameRate}fps', overflow: TextOverflow.ellipsis),
                          trailing: SizedBox(
                            width: 110,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Chip(
                                label: Text(cam.status, style: const TextStyle(fontSize: 10)),
                                backgroundColor: cam.status == 'online' ? Colors.green.shade100 : Colors.grey.shade200,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showEditDialog(cam), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => _confirmDelete(cam), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            ]),
                          ),
                        )),
                    ]),
                  ),
                ),
              ),
            ),

            // ── ABOUT TAB ───────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.headerGradient),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 12),
                      const Text('AttendanceAI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gray900)),
                      const Text('Face Recognition Attendance System', style: TextStyle(color: AppColors.gray500, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary100, borderRadius: BorderRadius.circular(999)),
                        child: const Text('v1.0.0', style: TextStyle(color: AppColors.primary700, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(children: [
                    _aboutRow(Icons.computer_outlined, 'Backend', 'FastAPI + Python'),
                    const Divider(height: 1),
                    _aboutRow(Icons.face_outlined, 'Face Recognition', 'CompreFace'),
                    const Divider(height: 1),
                    _aboutRow(Icons.storage_outlined, 'Database', 'PostgreSQL'),
                    const Divider(height: 1),
                    _aboutRow(Icons.stream_outlined, 'Streaming', 'MJPEG over HTTP'),
                    const Divider(height: 1),
                    _aboutRow(Icons.bolt_outlined, 'Real-time', 'WebSocket'),
                  ]),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Current Server', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(ServerConfig.baseUrl, style: const TextStyle(color: AppColors.primary600, fontSize: 13, fontFamily: 'monospace')),
                    ]),
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: AppColors.primary600, size: 20),
    title: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
    trailing: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray900)),
    dense: true,
  );
}
