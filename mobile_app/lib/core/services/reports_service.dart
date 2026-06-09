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

  Future<Map<String, dynamic>> getWeeklyTrend() async {
    return await _client.get('/reports/weekly-trend');
  }

  Future<List<dynamic>> getLateArrivals({String? date}) async {
    final q = date != null ? '?date=$date' : '';
    final data = await _client.get('/reports/late-arrivals$q');
    return data as List;
  }

  Future<List<AttendanceRecord>> getChildAttendance(String childId) async {
    final data = await _client.get('/parent/children/$childId/attendance');
    final attendanceList = (data['attendance'] as List? ?? []);
    return attendanceList.map((e) => AttendanceRecord.fromJson({
      ...e as Map<String, dynamic>,
      'student_id': childId,
    })).toList();
  }

  Future<List<AttendanceRecord>> getByDateRange(String start, String end) async {
    final data = await _client.get('/attendance?start_date=$start&end_date=$end');
    return (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }
}
