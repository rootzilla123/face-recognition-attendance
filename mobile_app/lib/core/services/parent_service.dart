import '../api/api_client.dart';
import '../models/student.dart';
import '../models/attendance.dart';

class ParentService {
  final _client = ApiClient();

  Future<List<Student>> getChildren() async {
    final data = await _client.get('/parent/children');
    return (data as List).map((e) => Student.fromJson(e)).toList();
  }

  Future<void> linkChild(String studentId) =>
      _client.post('/parent/children/link', {'student_id': studentId});

  Future<void> unlinkChild(String studentId) =>
      _client.delete('/parent/children/$studentId/unlink');

  Future<List<AttendanceRecord>> getChildAttendance(String studentId) async {
    final data = await _client.get('/parent/children/$studentId/attendance');
    final list = data['attendance'] as List;
    return list.map((e) => AttendanceRecord.fromJson({...e, 'student_id': studentId})).toList();
  }

  Future<Map<String, dynamic>> getChildFees(String studentId) async {
    return await _client.get('/parent/children/$studentId/fees');
  }
}
