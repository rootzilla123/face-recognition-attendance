import 'package:flutter/material.dart';
import '../core/models/user.dart';
import '../core/services/pocketbase_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool isLoading = false;
  String? error;

  AppUser? get user => _user ?? _fromPb();
  bool get isLoggedIn => PocketBaseService.isLoggedIn;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isTeacher => user?.isTeacher ?? false;
  bool get isStudent => user?.isStudent ?? false;
  bool get isParent => user?.isParent ?? false;
  bool get isVerified => PocketBaseService.isVerified;

  AppUser? _fromPb() {
    final u = PocketBaseService.user;
    if (u == null) return null;
    return AppUser(
      id: u['id'] ?? '',
      email: u['email'] ?? '',
      role: u['role'] ?? 'student',
      fullName: u['name'] ?? '',
      isActive: true,
      isVerified: u['verified'] == true,
    );
  }

  void loadFromSession() {
    _user = _fromPb();
    notifyListeners();
  }

  Future<bool> loginWithGoogle({String defaultRole = 'student'}) async {
    isLoading = true; error = null; notifyListeners();
    try {
      final record = await PocketBaseService.signInWithGoogle(defaultRole: defaultRole);
      _user = AppUser(
        id: record['id'] ?? '',
        email: record['email'] ?? '',
        role: record['role'] ?? defaultRole,
        fullName: record['name'] ?? '',
        isActive: true,
        isVerified: true, // Google accounts are auto-verified
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true; error = null; notifyListeners();
    try {
      final record = await PocketBaseService.login(email, password);
      _user = AppUser(
        id: record['id'] ?? '',
        email: record['email'] ?? '',
        role: record['role'] ?? 'student',
        fullName: record['name'] ?? '',
        isActive: true,
        isVerified: record['verified'] == true,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await PocketBaseService.logout();
    _user = null;
    notifyListeners();
  }
}
