import 'package:flutter/material.dart';
import '../core/models/student.dart';
import '../core/models/attendance.dart';
import '../core/services/parent_service.dart';

class ParentProvider extends ChangeNotifier {
  final _service = ParentService();
  List<Student> children = [];
  Map<String, List<AttendanceRecord>> childAttendance = {};
  Map<String, Map<String, dynamic>> childFees = {};
  bool isLoading = false;
  String? error;

  Future<void> fetchChildren() async {
    isLoading = true; error = null; notifyListeners();
    try { children = await _service.getChildren(); } catch (e) { error = e.toString(); }
    isLoading = false; notifyListeners();
  }

  Future<bool> linkChild(String studentId) async {
    try {
      await _service.linkChild(studentId);
      await fetchChildren();
      return true;
    } catch (e) { error = e.toString(); notifyListeners(); return false; }
  }

  Future<void> fetchChildAttendance(String studentId) async {
    try {
      childAttendance[studentId] = await _service.getChildAttendance(studentId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchChildFees(String studentId) async {
    try {
      childFees[studentId] = await _service.getChildFees(studentId);
      notifyListeners();
    } catch (_) {}
  }
}
