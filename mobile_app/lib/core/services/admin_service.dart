import '../api/api_client.dart';

class AdminService {
  final _client = ApiClient();

  Future<List<dynamic>> getUsers() async => await _client.get('/admin/users');
  Future<void> toggleUser(String id) => _client.post('/admin/users/$id/toggle', {});
  Future<List<dynamic>> getTeachers() async => await _client.get('/admin/teachers');
  Future<List<dynamic>> getTeacherAssignments(String teacherId) async {
    // Returns list of cameras assigned to this teacher
    final teachers = await _client.get('/admin/teachers');
    final teacher = (teachers as List).firstWhere(
      (t) => t['id'].toString() == teacherId,
      orElse: () => {'assigned_camera_ids': []},
    );
    final ids = (teacher['assigned_camera_ids'] as List? ?? []);
    if (ids.isEmpty) return [];
    final cameras = await _client.get('/cameras');
    return (cameras as List).where((c) => ids.contains(c['id'])).toList();
  }
  Future<dynamic> getEnrollmentStatus() => _client.get('/admin/students/enrollment-status');
  Future<void> assignCameras(String teacherId, List<int> cameraIds) =>
      _client.put('/admin/teachers/$teacherId/cameras', {'camera_ids': cameraIds});
}
