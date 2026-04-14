import 'package:flutter/material.dart';
import '../core/models/announcement.dart';
import '../core/services/announcement_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final _service = AnnouncementService();
  List<Announcement> items = [];
  bool isLoading = false;
  String? error;

  Future<void> fetch() async {
    isLoading = true; error = null; notifyListeners();
    try { items = await _service.getAll(); } catch (e) { error = e.toString(); }
    isLoading = false; notifyListeners();
  }

  Future<bool> create(String title, String content, List<String> roles) async {
    try {
      final a = await _service.create(title, content, roles);
      items.insert(0, a);
      notifyListeners();
      return true;
    } catch (e) { error = e.toString(); notifyListeners(); return false; }
  }

  Future<bool> delete(String id) async {
    try {
      await _service.delete(id);
      items.removeWhere((a) => a.id == id);
      notifyListeners();
      return true;
    } catch (e) { error = e.toString(); notifyListeners(); return false; }
  }
}
