import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/camera.dart';

class CameraService {
  final ApiClient _client = ApiClient();

  Future<List<Camera>> getCameras() async {
    final data = await _client.get(Endpoints.cameras);
    return (data as List).map((e) => Camera.fromJson(e)).toList();
  }

  Future<Camera> addCamera({
    required String name,
    required String location,
    required String streamUrl,
    required String protocol,
    String? username,
    String? password,
    int frameRate = 5,
  }) async {
    final data = await _client.post(Endpoints.cameras, {
      'name': name,
      'location': location,
      'stream_url': streamUrl,
      'protocol': protocol,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      'frame_rate': frameRate,
      'is_active': true,
    });
    return Camera.fromJson(data);
  }

  Future<Camera> updateCamera(int id, Map<String, dynamic> fields) async {
    final data = await _client.put(Endpoints.cameraById(id), fields);
    return Camera.fromJson(data);
  }

  Future<void> deleteCamera(int id) async {
    await _client.delete(Endpoints.cameraById(id));
  }

  Future<void> startCamera(int id) async {
    await _client.post(Endpoints.cameraStart(id), {});
  }

  Future<void> stopCamera(int id) async {
    await _client.post(Endpoints.cameraStop(id), {});
  }
}
