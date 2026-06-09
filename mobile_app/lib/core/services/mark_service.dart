import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/mark.dart';
import 'package:http/http.dart' as http;

class MarkService {
  final _client = ApiClient();

  Future<List<Mark>> getMarks({String? studentId, String? term, String? subject}) async {
    String url = Endpoints.marks;
    List<String> params = [];
    if (studentId != null) params.add('student_id=$studentId');
    if (term != null) params.add('term=$term');
    if (subject != null) params.add('subject=$subject');
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final data = await _client.get(url);
    return (data as List).map((e) => Mark.fromJson(e)).toList();
  }

  Future<Mark> createMark(Map<String, dynamic> data) async {
    final resp = await _client.post(Endpoints.marks, data);
    return Mark.fromJson(resp);
  }

  Future<Mark> updateMark(String id, Map<String, dynamic> data) async {
    final resp = await _client.put(Endpoints.markById(id), data);
    return Mark.fromJson(resp);
  }

  Future<void> deleteMark(String id) async {
    await _client.delete(Endpoints.markById(id));
  }

  Future<void> publishMark(String id) async {
    await _client.post(Endpoints.markPublish(id), {});
  }

  Future<List<Mark>> getMyMarks() async {
    final data = await _client.get(Endpoints.myMarks);
    return (data as List).map((e) => Mark.fromJson(e)).toList();
  }

  Future<List<Mark>> getChildMarks(String studentId) async {
    final data = await _client.get(Endpoints.childMarks(studentId));
    return (data as List).map((e) => Mark.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> bulkUpload(String filePath, String term) async {
    final file = await http.MultipartFile.fromPath('file', filePath);
    final resp = await _client.postMultipart(
      Endpoints.marksBulk(term),
      {},
      file: file,
    );
    return resp as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSubjectAnalytics(String subject, String term) async {
    final data = await _client.get(Endpoints.marksAnalytics(subject, term));
    return data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getConsolidatedReport(String studentId, String term) async {
    final data = await _client.get(Endpoints.marksConsolidated(studentId, term));
    return data as Map<String, dynamic>;
  }
}
