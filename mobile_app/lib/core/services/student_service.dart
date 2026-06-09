import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/student.dart';
import 'connectivity_service.dart';

class StudentService {
  final ApiClient _client = ApiClient();

  Future<List<Student>> getStudents() async {
    try {
      final data = await _client.get(Endpoints.students);
      await ConnectivityService.cacheJson('students', jsonEncode(data));
      return (data as List).map((e) => Student.fromJson(e)).toList();
    } on OfflineException {
      final cached = await ConnectivityService.getCached('students');
      if (cached == null) rethrow;
      return (jsonDecode(cached) as List).map((e) => Student.fromJson(e)).toList();
    }
  }

  Future<Student> createStudent({
    required String studentId,
    required String fullName,
    required String gradeLevel,
    String? section,
    required String parentPhone,
    required String parentEmail,
    required http.MultipartFile photo,
  }) async {
    final data = await _client.postMultipart(
      Endpoints.students,
      {
        'student_id': studentId,
        'full_name': fullName,
        'grade_level': gradeLevel,
        if (section != null) 'section': section,
        'parent_phone': parentPhone,
        'parent_email': parentEmail,
      },
      file: photo,
    );
    return Student.fromJson(data);
  }

  Future<void> deleteStudent(String studentId) async {
    await _client.delete(Endpoints.studentById(studentId));
  }

  Future<Student> updateStudent(String studentId, Map<String, dynamic> fields) async {
    final data = await _client.put(Endpoints.studentById(studentId), fields);
    return Student.fromJson(data);
  }

  Future<Student> getMyProfile() async {
    final data = await _client.get(Endpoints.studentMe);
    return Student.fromJson(data);
  }
}
