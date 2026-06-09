import '../api/api_client.dart';

class MessageService {
  final ApiClient _client = ApiClient();

  Future<List<dynamic>> getConversations() async => await _client.get('/messages/conversations');
  Future<List<dynamic>> getMessages(String conversationId) async => await _client.get('/messages/$conversationId');
  Future<void> sendMessage(String recipientId, String content) async {
    await _client.post('/messages', {'recipient_id': recipientId, 'content': content});
  }
}
