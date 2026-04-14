import '../api/api_client.dart';

class AdminService {
  final _client = ApiClient();

  Future<List<dynamic>> getUsers() async => await _client.get('/admin/users');
  Future<void> toggleUser(String id) => _client.post('/admin/users/$id/toggle', {});
  Future<List<dynamic>> getTeachers() async => await _client.get('/admin/teachers');
  Future<dynamic> getEnrollmentStatus() => _client.get('/admin/students/enrollment-status');
  Future<void> assignCameras(String teacherId, List<int> cameraIds) =>
      _client.put('/admin/teachers/$teacherId/cameras', {'camera_ids': cameraIds});
}
