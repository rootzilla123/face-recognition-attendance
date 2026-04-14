import 'package:flutter/material.dart';
import '../core/models/attendance.dart';
import '../core/services/attendance_service.dart';
import '../core/services/student_service.dart';
import '../core/services/reports_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();
  final StudentService _studentService = StudentService();
  final ReportsService _reports = ReportsService();

  List<AttendanceRecord> todayRecords = [];
  List<AttendanceRecord> reportRecords = [];
  AttendanceStats? stats;
  bool isLoading = false;
  String? error;
  Map<String, String> studentNames = {};

  String nameFor(String studentId) => studentNames[studentId] ?? 'Student #$studentId';

  Future<void> _loadStudentNames() async {
    try {
      final students = await _studentService.getStudents();
      studentNames = {for (final s in students) s.id: s.fullName};
      for (final s in students) { studentNames[s.studentId] = s.fullName; }
    } catch (_) {}
  }

  Future<void> fetchToday() async {
    isLoading = true; error = null; notifyListeners();
    try {
      final results = await Future.wait([
        _service.getTodayAttendance(),
        _service.getStats(),
        _loadStudentNames(),
      ]);
      todayRecords = results[0] as List<AttendanceRecord>;
      stats = results[1] as AttendanceStats;
    } catch (e) { error = e.toString(); }
    isLoading = false; notifyListeners();
  }

  Future<void> fetchMyAttendance() async {
    isLoading = true; error = null; notifyListeners();
    try {
      todayRecords = await _reports.getMyAttendance();
    } catch (e) { error = e.toString(); }
    isLoading = false; notifyListeners();
  }

  Future<void> fetchByDateRange(String start, String end) async {
    isLoading = true; error = null; reportRecords = []; notifyListeners();
    try {
      reportRecords = await _service.getByDateRange(start, end);
    } catch (e) { error = e.toString(); }
    isLoading = false; notifyListeners();
  }

  void setReportRecords(List<AttendanceRecord> records) {
    reportRecords = records;
    notifyListeners();
  }
}
