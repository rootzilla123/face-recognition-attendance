import '../utils/server_config.dart';

class Endpoints {
  static String get base => ServerConfig.baseUrl;
  static String get apiV1 => '${ServerConfig.baseUrl}/api/v1';

  static const String students = '/students';
  static const String attendance = '/attendance';
  static const String attendanceToday = '/attendance/today';
  static const String attendanceStats = '/attendance/stats';
  static const String cameras = '/cameras';
  static const String reports = '/reports';
  static const String health = '/health';

  static String studentById(String id) => '/students/$id';
  static String studentPhoto(String studentId) => '$apiV1/students/$studentId/photo';
  static String get studentMe => '/students/me';
  static String get teacherMe => '/admin/teacher/me';
  static String cameraById(int id) => '/cameras/$id';
  static String cameraStart(int id) => '/cameras/$id/start';
  static String cameraStop(int id) => '/cameras/$id/stop';
  static String cameraStatus(int id) => '/cameras/$id/status';
  static String attendanceRange(String start, String end) =>
      '/attendance?start_date=$start&end_date=$end';
  static String get attendanceMy => '/attendance/my';
  static String get gradeSummary => '/reports/grade-summary';
  static String get dailySummary => '/reports/daily-summary';
  static String studentReport(String id) => '/reports/student/$id';
  static String get resetPassword => '/auth/reset-password';
  static String get registerTeacher => '/auth/register/teacher';
  static String get registerAdmin => '/auth/register/admin';

  // Marks
  static const String marks = '/marks';
  static String markById(String id) => '/marks/$id';
  static String markPublish(String id) => '/marks/$id/publish';
  static String marksBulk(String term) => '/marks/bulk?term=${Uri.encodeComponent(term)}';
  static String marksAnalytics(String subject, String term) =>
      '/marks/analytics/subject?subject=${Uri.encodeComponent(subject)}&term=${Uri.encodeComponent(term)}';
  static String marksConsolidated(String studentId, String term) =>
      '/marks/consolidated/$studentId?term=${Uri.encodeComponent(term)}';
  static const String myMarks = '/my-marks';
  static String childMarks(String studentId) => '/child-marks/$studentId';

  // WebSocket — handles both http→ws and https→wss
  static String get wsUrl {
    final base = ServerConfig.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/ws';
  }

  // MJPEG stream
  static String mjpegStream(int cameraId) =>
      '$apiV1/cameras/$cameraId/stream';

  // Video clip for an attendance record
  static String attendanceClip(String attendanceId) =>
      '$apiV1/attendance/$attendanceId/clip';
}
