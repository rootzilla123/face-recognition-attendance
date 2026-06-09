import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/api/endpoints.dart';
import '../core/models/attendance.dart';
import '../core/services/notification_service.dart';
import 'attendance_provider.dart';

class WebSocketProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool isConnected = false;
  List<Map<String, dynamic>> recentDetections = [];
  Map<String, List<Map<String, dynamic>>> cameraDetections = {};
  Map<String, String> cameraStatuses = {}; // cameraId → 'online'|'offline'
  StreamSubscription? _sub;
  bool _disposed = false;
  BuildContext? _context;

  void setContext(BuildContext context) => _context = context;

  void connect() {
    if (_disposed) return;
    disconnect(); // close any existing connection first
    try {
      _channel = WebSocketChannel.connect(Uri.parse(Endpoints.wsUrl));
      isConnected = true;
      notifyListeners();
      _sub = _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String);
            final type = json['type'];
            if (type == 'recognition_event') {
              final cameraId = json['camera_id']?.toString() ?? '';
              final detections = (json['detections'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              cameraDetections[cameraId] = detections;
              for (final d in detections) {
                final subjects = d['subjects'] as List?;
                final studentId = subjects?.isNotEmpty == true
                    ? subjects!.first['subject']?.toString() ?? ''
                    : d['student_id']?.toString() ?? '';
                if (studentId.isNotEmpty) {
                  final conf = subjects?.isNotEmpty == true
                      ? (subjects!.first['similarity'] as num?)?.toDouble() ?? 0.0
                      : (d['confidence'] as num?)?.toDouble() ?? 0.0;
                  recentDetections.insert(0, {
                    'type': 'attendance',
                    'student_id': studentId,
                    'camera_location': cameraId,
                    'confidence': conf,
                    'timestamp': json['timestamp'],
                  });
                  if (recentDetections.length > 20) recentDetections.removeLast();
                  NotificationService.showAttendance(studentId, cameraId, conf);
                  // Push live record into AttendanceProvider
                  if (_context != null) {
                    try {
                      _context!.read<AttendanceProvider>().injectLiveRecord(AttendanceRecord(
                        id: 'ws_${DateTime.now().millisecondsSinceEpoch}',
                        studentId: studentId,
                        cameraLocation: cameraId,
                        timestamp: DateTime.now(),
                        confidenceScore: conf,
                      ));
                    } catch (_) {}
                  }
                }
              }
              notifyListeners();
            } else if (type == 'attendance' || type == 'recognition') {
              recentDetections.insert(0, json);
              if (recentDetections.length > 20) recentDetections.removeLast();
              notifyListeners();
              final studentId = json['student_id']?.toString() ?? 'Unknown';
              final location = json['camera_location']?.toString() ?? '';
              final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
              NotificationService.showAttendance(studentId, location, confidence);
            } else if (type == 'camera_status') {
              final cameraId = json['camera_id']?.toString() ?? '';
              final status = json['status']?.toString() ?? 'offline';
              final cameraName = json['camera_name']?.toString() ?? 'Camera';
              cameraStatuses[cameraId] = status;
              notifyListeners();
              if (status == 'offline') {
                NotificationService.showCameraOffline(cameraName);
              }
            }
          } catch (_) {}
        },
        onDone: () => _setDisconnected(),
        onError: (_) => _setDisconnected(),
      );
    } catch (_) {
      _setDisconnected();
    }
  }

  void _setDisconnected() {
    if (_disposed) return;
    isConnected = false;
    notifyListeners();
    Future.delayed(const Duration(seconds: 5), () {
      if (!_disposed) connect();
    });
  }

  void disconnect() {
    _sub?.cancel();
    _channel?.sink.close();
    isConnected = false;
  }

  void clearDetections() {
    recentDetections.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    disconnect();
    super.dispose();
  }
}
