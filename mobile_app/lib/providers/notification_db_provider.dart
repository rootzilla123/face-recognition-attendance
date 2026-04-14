import 'package:flutter/material.dart';
import '../core/models/notification_item.dart';
import '../core/services/notification_db_service.dart';

class NotificationDbProvider extends ChangeNotifier {
  final _service = NotificationDbService();
  List<NotificationItem> items = [];
  int unreadCount = 0;
  Map<String, dynamic> prefs = {'sms': true, 'email': true, 'in_app': true, 'language': 'en'};
  bool isLoading = false;
  String? error;

  Future<void> fetch() async {
    isLoading = true; error = null; notifyListeners();
    try {
      items = await _service.getAll();
      unreadCount = items.where((n) => !n.isRead).length;
    } catch (e) { error = e.toString(); }
    isLoading = false; notifyListeners();
  }

  Future<void> markRead(String id) async {
    try {
      await _service.markRead(id);
      items = items.map((n) => n.id == id ? NotificationItem(id: n.id, title: n.title, message: n.message, type: n.type, isRead: true, createdAt: n.createdAt) : n).toList();
      unreadCount = items.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _service.markAllRead();
      items = items.map((n) => NotificationItem(id: n.id, title: n.title, message: n.message, type: n.type, isRead: true, createdAt: n.createdAt)).toList();
      unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPrefs() async {
    try { prefs = await _service.getPreferences(); notifyListeners(); } catch (_) {}
  }

  Future<void> savePrefs(Map<String, dynamic> p) async {
    try { await _service.updatePreferences(p); prefs = p; notifyListeners(); } catch (_) {}
  }
}
