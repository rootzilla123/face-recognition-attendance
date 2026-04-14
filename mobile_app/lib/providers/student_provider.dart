import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/models/student.dart';
import '../core/services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentService _service = StudentService();

  List<Student> students = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchStudents() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      students = await _service.getStudents();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createStudent({
    required String studentId,
    required String fullName,
    required String gradeLevel,
    String? section,
    required String parentPhone,
    required String parentEmail,
    required http.MultipartFile photo,
  }) async {
    try {
      await _service.createStudent(
        studentId: studentId,
        fullName: fullName,
        gradeLevel: gradeLevel,
        section: section,
        parentPhone: parentPhone,
        parentEmail: parentEmail,
        photo: photo,
      );
      await fetchStudents();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(String studentId) async {
    try {
      await _service.deleteStudent(studentId);
      await fetchStudents();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStudent(String studentId, Map<String, dynamic> fields) async {
    try {
      await _service.updateStudent(studentId, fields);
      await fetchStudents();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
