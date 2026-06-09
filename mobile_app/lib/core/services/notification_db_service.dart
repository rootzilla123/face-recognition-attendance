import '../api/api_client.dart';
import '../models/notification_item.dart';

class NotificationDbService {
  final _client = ApiClient();

  Future<List<NotificationItem>> getAll() async {
    final data = await _client.get('/notifications');
    return (data as List).map((e) => NotificationItem.fromJson(e)).toList();
  }

  Future<List<NotificationItem>> getAllTypes({int limit = 50}) async {
    final data = await _client.get('/notifications/all-types?limit=$limit');
    return (data as List).map((e) => NotificationItem.fromJson(e)).toList();
  }

  Future<List<NotificationItem>> getSmsHistory({int limit = 30}) async {
    final data = await _client.get('/notifications/sms-history?limit=$limit');
    return (data as List).map((e) => NotificationItem.fromJson(e)).toList();
  }

  Future<int> getUnreadCount() async {
    final data = await _client.get('/notifications/unread-count');
    return data['unread_count'] ?? 0;
  }

  Future<void> markRead(String id) => _client.post('/notifications/$id/read', {});
  Future<void> markAllRead() => _client.post('/notifications/read-all', {});

  Future<Map<String, dynamic>> getPreferences() async {
    final data = await _client.get('/notifications/preferences');
    return Map<String, dynamic>.from(data);
  }

  Future<void> updatePreferences(Map<String, dynamic> prefs) =>
      _client.put('/notifications/preferences', prefs);

  Future<Map<String, dynamic>> sendTest({String? phone}) async {
    final path = phone != null
        ? '/notifications/send-test?phone=$phone'
        : '/notifications/send-test';
    final data = await _client.post(path, {});
    return Map<String, dynamic>.from(data);
  }
}
