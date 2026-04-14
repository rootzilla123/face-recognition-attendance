import '../api/api_client.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final _client = ApiClient();

  Future<List<Announcement>> getAll() async {
    final data = await _client.get('/announcements');
    return (data as List).map((e) => Announcement.fromJson(e)).toList();
  }

  Future<Announcement> create(String title, String content, List<String> roles) async {
    final data = await _client.post('/announcements', {'title': title, 'content': content, 'target_roles': roles});
    return Announcement.fromJson(data);
  }

  Future<void> delete(String id) => _client.delete('/announcements/$id');
}
