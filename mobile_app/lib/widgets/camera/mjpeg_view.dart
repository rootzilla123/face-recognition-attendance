import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Renders a live MJPEG stream by reading multipart/x-mixed-replace HTTP response
class MjpegView extends StatefulWidget {
  final String streamUrl;

  const MjpegView({super.key, required this.streamUrl});

  @override
  State<MjpegView> createState() => _MjpegViewState();
}

class _MjpegViewState extends State<MjpegView> {
  Uint8List? _frame;
  bool _error = false;
  StreamSubscription? _sub;
  http.Client? _client;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void didUpdateWidget(MjpegView old) {
    super.didUpdateWidget(old);
    if (old.streamUrl != widget.streamUrl) {
      _stopStream();
      _startStream();
    }
  }

  void _startStream() {
    _error = false;
    _client = http.Client();
    final request = http.Request('GET', Uri.parse(widget.streamUrl));

    _client!.send(request).then((response) {
      final List<int> buf = [];
      _sub = response.stream.listen(
        (chunk) {
          buf.addAll(chunk);
          // Find JPEG start (FF D8) and end (FF D9) markers
          int start = -1;
          for (int i = 0; i < buf.length - 1; i++) {
            if (buf[i] == 0xFF && buf[i + 1] == 0xD8) {
              start = i;
              break;
            }
          }
          if (start == -1) return;

          for (int i = start; i < buf.length - 1; i++) {
            if (buf[i] == 0xFF && buf[i + 1] == 0xD9) {
              final jpeg = Uint8List.fromList(buf.sublist(start, i + 2));
              buf.removeRange(0, i + 2);
              if (mounted) setState(() => _frame = jpeg);
              break;
            }
          }
        },
        onError: (_) { if (mounted) setState(() => _error = true); },
        onDone: () { if (mounted) setState(() => _error = true); },
      );
    }).catchError((_) {
      if (mounted) setState(() => _error = true);
    });
  }

  void _stopStream() {
    _sub?.cancel();
    _client?.close();
    _sub = null;
    _client = null;
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.videocam_off, color: Colors.white54, size: 40),
            SizedBox(height: 8),
            Text('Stream unavailable', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      );
    }

    if (_frame == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
            SizedBox(height: 8),
            Text('Connecting...', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      );
    }

    return Image.memory(_frame!, fit: BoxFit.cover, gaplessPlayback: true);
  }
}
