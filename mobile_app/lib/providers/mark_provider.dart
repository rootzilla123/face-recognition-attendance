import 'package:flutter/material.dart';
import '../core/models/mark.dart';
import '../core/services/mark_service.dart';

class MarkProvider extends ChangeNotifier {
  final _service = MarkService();
  List<Mark> marks = [];
  Map<String, List<Mark>> childMarks = {};
  bool isLoading = false;
  String? error;

  Future<void> fetchMarks({String? studentId, String? term, String? subject}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      marks = await _service.getMarks(studentId: studentId, term: term, subject: subject);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> createMark(Map<String, dynamic> data) async {
    try {
      await _service.createMark(data);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMark(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateMark(id, data);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMark(String id) async {
    try {
      await _service.deleteMark(id);
      marks.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> publishMark(String id) async {
    try {
      await _service.publishMark(id);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMyMarks() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      marks = await _service.getMyMarks();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchChildMarks(String studentId) async {
    try {
      childMarks[studentId] = await _service.getChildMarks(studentId);
      notifyListeners();
    } catch (_) {}
  }
}
