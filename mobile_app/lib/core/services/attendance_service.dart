import 'dart:convert';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/attendance.dart';
import 'connectivity_service.dart';

class AttendanceService {
  final ApiClient _client = ApiClient();

  Future<List<AttendanceRecord>> getTodayAttendance() async {
    try {
      final data = await _client.get(Endpoints.attendanceToday);
      final list = (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
      await ConnectivityService.cacheJson('attendance_today', jsonEncode(data));
      return list;
    } on OfflineException {
      return _cachedList('attendance_today');
    }
  }

  Future<AttendanceStats> getStats() async {
    try {
      final data = await _client.get(Endpoints.attendanceStats);
      await ConnectivityService.cacheJson('attendance_stats', jsonEncode(data));
      return AttendanceStats.fromJson(data);
    } on OfflineException {
      final cached = await ConnectivityService.getCached('attendance_stats');
      if (cached != null) return AttendanceStats.fromJson(jsonDecode(cached));
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getMyAttendance() async {
    try {
      final data = await _client.get(Endpoints.attendanceMy);
      final list = (data as List).map((e) => AttendanceRecord.fromJson(e)).toList();
      await ConnectivityService.cacheJson('attendance_my', jsonEncode(data));
      return list;
    } on OfflineException {
      return _cachedList('attendance_my');
    }
  }

  Future<List<AttendanceRecord>> getByDateRange(String start, String end) async {
    final cacheKey = 'attendance_range_${start}_$end';
    try {
      final data = await _client.get(Endpoints.attendanceRange(start, end));
      List records;
      if (data is List) {
        records = data;
      } else if (data is Map && data.containsKey('records')) {
        records = data['records'] as List;
      } else {
        records = [];
      }
      await ConnectivityService.cacheJson(cacheKey, jsonEncode(records));
      return records.map((e) => AttendanceRecord.fromJson(e)).toList();
    } on OfflineException {
      return _cachedList(cacheKey);
    }
  }

  Future<void> createManualAttendance(String studentId, String location) async {
    await _client.post('/attendance/manual', {
      'student_id': studentId,
      'location': location,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AttendanceRecord>> _cachedList(String key) async {
    final cached = await ConnectivityService.getCached(key);
    if (cached == null) throw const OfflineException();
    return (jsonDecode(cached) as List).map((e) => AttendanceRecord.fromJson(e)).toList();
  }
}
