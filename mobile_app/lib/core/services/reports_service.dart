import '../api/api_client.dart';
import '../models/attendance.dart';

class ReportsService {
  final _client = ApiClient();

  Future<Map<String, dynamic>> getDailySummary({String? date}) async {
    final q = date != null ? '?date=$date' : '';
    return await _client.get('/reports/daily-summary$q');
  }

  Future<Map<String, dynamic>> getGradeSummary({String? date}) async {
    final q = date != null ? '?date=$date' : '';
    return await _client.get('/reports/grade-summary$q');
  }

  Future<List<AttendanceRecord>> getStudentReport(String studentId, String start, String end) async {
    final data = await _client.get('/reports/student/$studentId?start_date=$start&end_date=$end');
    return (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  Future<List<AttendanceRecord>> getMyAttendance() async {
    final data = await _client.get('/attendance/my');
    return (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }
}
