import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/pocketbase_service.dart';
import 'endpoints.dart';

class ApiClient {
  final http.Client _client = http.Client();

  Uri _uri(String path) => Uri.parse('${Endpoints.apiV1}$path');

  Map<String, String> _headers() => PocketBaseService.authHeaders;

  Future<dynamic> get(String path) async {
    final res = await _client.get(_uri(path), headers: _headers());
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _client.post(_uri(path), headers: _headers(), body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await _client.put(_uri(path), headers: _headers(), body: jsonEncode(body));
    return _handle(res);
  }

  Future<void> delete(String path) async {
    final res = await _client.delete(_uri(path), headers: _headers());
    if (res.statusCode >= 400) throw Exception('DELETE $path failed: ${res.statusCode}');
  }

  Future<dynamic> postMultipart(String path, Map<String, String> fields, {required http.MultipartFile file}) async {
    final req = http.MultipartRequest('POST', _uri(path));
    final h = Map<String, String>.from(_headers())..remove('Content-Type');
    req.headers.addAll(h);
    req.fields.addAll(fields);
    req.files.add(file);
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode == 401) throw Exception('Not authenticated');
    if (res.statusCode >= 400) {
      try {
        final body = jsonDecode(res.body);
        throw Exception(body['detail'] ?? 'Request failed: ${res.statusCode}');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Request failed: ${res.statusCode}');
      }
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  void dispose() => _client.close();
}
