import '../api/api_client.dart';
import '../api/endpoints.dart';

class HealthService {
  static Future<bool> check() async {
    try {
      final client = ApiClient();
      await client.get(Endpoints.health);
      return true;
    } catch (_) {
      return false;
    }
  }
}
