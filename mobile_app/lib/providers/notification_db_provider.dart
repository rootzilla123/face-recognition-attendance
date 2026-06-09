import 'package:flutter/material.dart';
import '../core/models/notification_item.dart';
import '../core/services/notification_db_service.dart';

class NotificationDbProvider extends ChangeNotifier {
  final _service = NotificationDbService();
  List<NotificationItem> items = [];
  List<NotificationItem> smsHistory = [];
  int unreadCount = 0;
  Map<String, dynamic> prefs = {'sms': true, 'email': true, 'in_app': true, 'language': 'en'};
  String? phone;
  String? email;
  String? role;
  bool smsEnabled = false;
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

  Future<void> fetchSmsHistory() async {
    try {
      smsHistory = await _service.getSmsHistory();
      notifyListeners();
    } catch (_) {}
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
    try {
      final data = await _service.getPreferences();
      final prefsData = data['preferences'];
      if (prefsData is Map<String, dynamic>) {
        prefs = prefsData;
      }
      phone = data['phone']?.toString();
      email = data['email']?.toString();
      role = data['role']?.toString();
      smsEnabled = data['sms_enabled'] == true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> savePrefs(Map<String, dynamic> p) async {
    try { await _service.updatePreferences(p); prefs = p; notifyListeners(); } catch (_) {}
  }

  Future<Map<String, dynamic>> sendTest({String? phone}) async {
    try {
      return await _service.sendTest(phone: phone);
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
