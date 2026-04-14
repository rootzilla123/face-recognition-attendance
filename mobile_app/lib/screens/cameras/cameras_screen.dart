import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/camera_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../core/models/camera.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../core/api/endpoints.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/camera/mjpeg_view.dart';
import '../../widgets/camera/recognition_overlay.dart';
class CamerasScreen extends StatefulWidget {
  const CamerasScreen({super.key});

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<CameraProvider>().fetchCameras());
  }

  void _showAddCamera() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddCameraSheet(),
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
              if (mounted) showSnack(context, ok ? 'Camera removed' : 'Failed', error: !ok);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CameraProvider>();
    final active = prov.cameras.where((c) => c.isActive).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<CameraProvider>().fetchCameras(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: 'Cameras',
                subtitle: 'Live feeds and camera management',
                action: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5)),
                  onPressed: _showAddCamera,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Camera'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: prov.isLoading
                  ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator())))
                  : prov.cameras.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.all(48),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.gray200),
                              ),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                const Text('📹', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                const Text('No Cameras Added', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.gray800)),
                                const SizedBox(height: 8),
                                const Text('Get started by adding your first CCTV camera', style: TextStyle(color: AppColors.gray500), textAlign: TextAlign.center),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: _showAddCamera,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Your First Camera'),
                                ),
                              ]),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CameraCard(camera: active[i], onDelete: () => _confirmDelete(active[i])),
                            ),
                            childCount: active.length,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraCard extends StatefulWidget {
  final Camera camera;
  final VoidCallback onDelete;
  const _CameraCard({required this.camera, required this.onDelete});

  @override
  State<_CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends State<_CameraCard> {
  Camera get camera => widget.camera;
  VoidCallback get onDelete => widget.onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Feed area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MjpegView(streamUrl: Endpoints.mjpegStream(camera.id)),
                // Face detection overlay from WebSocket
                Consumer<WebSocketProvider>(
                  builder: (ctx, ws, _) {
                    final rawDetections = ws.cameraDetections[camera.id.toString()] ?? [];
                    final detections = rawDetections.map((d) => Detection.fromJson(d)).toList();
                    return RecognitionOverlay(detections: detections);
                  },
                ),
                // Status badge top-left
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle, size: 8, color: camera.status == 'online' ? Colors.greenAccent : Colors.redAccent),
                      const SizedBox(width: 4),
                      Text(camera.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
                // FPS + active badge bottom-left
                Positioned(
                  bottom: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${camera.frameRate} FPS  •  ${camera.isActive ? "Active" : "Inactive"}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                // Action buttons top-right
                Positioned(
                  top: 10, right: 10,
                  child: Row(children: [
                    _actionBtn(
                      camera.isActive ? Icons.stop_circle_outlined : Icons.play_circle_outlined,
                      camera.isActive ? Colors.orange : Colors.green,
                      () async {
                        final ok = await context.read<CameraProvider>().toggleCamera(camera.id, camera.isActive);
                        if (!ok && context.mounted) showSnack(context, 'Failed', error: true);
                      },
                    ),
                    const SizedBox(width: 6),
                    _actionBtn(Icons.delete_outline, Colors.red, onDelete),
                  ]),
                ),
              ],
            ),
          ),
          // Info row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(camera.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900)),
                Text(camera.location, style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: camera.status == 'online' ? AppColors.success100 : AppColors.gray100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  camera.protocol.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: camera.status == 'online' ? AppColors.success700 : AppColors.gray600,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _AddCameraSheet extends StatefulWidget {
  const _AddCameraSheet();

  @override
  State<_AddCameraSheet> createState() => _AddCameraSheetState();
}

class _AddCameraSheetState extends State<_AddCameraSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _streamUrl = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _protocol = 'rtsp';
  bool _saving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await context.read<CameraProvider>().addCamera({
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'stream_url': _streamUrl.text.trim(),
      'protocol': _protocol,
      'username': _username.text.trim().isEmpty ? null : _username.text.trim(),
      'password': _password.text.trim().isEmpty ? null : _password.text.trim(),
    });
    setState(() => _saving = false);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        showSnack(context, 'Camera added');
      } else {
        showSnack(context, context.read<CameraProvider>().error ?? 'Failed', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Camera', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(_name, 'Camera Name', required: true),
              _field(_location, 'Location', required: true),
              _field(_streamUrl, 'Stream URL', required: true),
              DropdownButtonFormField<String>(
                value: _protocol,
                decoration: const InputDecoration(labelText: 'Protocol', border: OutlineInputBorder()),
                items: ['rtsp', 'http', 'local'].map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _protocol = v!),
              ),
              const SizedBox(height: 10),
              _field(_username, 'Username (optional)'),
              _field(_password, 'Password (optional)', obscure: true),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add Camera'),
                )),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool required = false, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }
}
