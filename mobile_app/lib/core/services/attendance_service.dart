import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/attendance.dart';

class AttendanceService {
  final ApiClient _client = ApiClient();

  Future<List<AttendanceRecord>> getTodayAttendance() async {
    final data = await _client.get(Endpoints.attendanceToday);
    return (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  Future<AttendanceStats> getStats() async {
    final data = await _client.get(Endpoints.attendanceStats);
    return AttendanceStats.fromJson(data);
  }

  Future<List<AttendanceRecord>> getMyAttendance() async {
    final data = await _client.get(Endpoints.attendanceMy);
    return (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }

  Future<List<AttendanceRecord>> getByDateRange(String start, String end) async {
    final data = await _client.get(Endpoints.attendanceRange(start, end));
    // Backend now returns paginated: {total, page, page_size, pages, records: [...]}
    // Handle both old list format and new paginated format
    if (data is List) {
      return data.map((e) => AttendanceRecord.fromJson(e)).toList();
    }
    if (data is Map && data.containsKey('records')) {
      return (data['records'] as List).map((e) => AttendanceRecord.fromJson(e)).toList();
    }
    return [];
  }
}
