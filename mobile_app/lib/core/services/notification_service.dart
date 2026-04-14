import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const settings = InitializationSettings(android: android, linux: linux);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> showAttendance(String studentId, String location, double confidence) async {
    if (!_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'attendance_channel',
        'Attendance Alerts',
        channelDescription: 'Live face recognition attendance events',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✅ Student Checked In',
      'Student #$studentId at $location (${(confidence * 100).toStringAsFixed(0)}% match)',
      details,
    );
  }
}
