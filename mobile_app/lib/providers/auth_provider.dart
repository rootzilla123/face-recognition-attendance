import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/user.dart';
import '../core/services/pocketbase_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool isLoading = false;
  String? error;

  // Holds Google sign-in state between step1 and step2
  String? _pendingFirebaseToken;
  String? _pendingGoogleName;
  String? get pendingGoogleName => _pendingGoogleName;

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

  /// Step 1: trigger Google/Firebase sign-in, get the user's name.
  /// Returns the display name on success, null on cancel/error.
  Future<String?> startGoogleSignIn() async {
    isLoading = true; error = null; notifyListeners();
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        isLoading = false; notifyListeners();
        return null;
      }

      final name = googleUser.displayName ?? googleUser.email.split('@').first;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final uc = await FirebaseAuth.instance.signInWithCredential(credential);
      if (uc.user == null) throw Exception('Firebase sign-in failed');

      _pendingFirebaseToken = await uc.user!.getIdToken();
      _pendingGoogleName = name;
      isLoading = false; notifyListeners();
      return name;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false; notifyListeners();
      return null;
    }
  }

  /// Step 2: exchange the Firebase token for a PocketBase session with the chosen role.
  Future<bool> completeGoogleSignIn(String role) async {
    if (_pendingFirebaseToken == null) return false;
    isLoading = true; error = null; notifyListeners();
    try {
      final data = await PocketBaseService.exchangeFirebaseToken(
        firebaseToken: _pendingFirebaseToken!,
        role: role,
        displayName: _pendingGoogleName ?? '',
      );
      final record = data['record'];
      _user = AppUser(
        id: record['id'] ?? '',
        email: record['email'] ?? '',
        role: record['role'] ?? role,
        fullName: record['name'] ?? _pendingGoogleName ?? '',
        isActive: true,
        isVerified: true,
      );
      _pendingFirebaseToken = null;
      _pendingGoogleName = null;
      isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false; notifyListeners();
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
      isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false; notifyListeners();
      return false;
    }
  }

  /// Single-step Google sign-in. It first checks if the user exists.
  /// If the user is new, returns false and sets [pendingGoogleName] 
  /// so the caller can navigate to RolePickerScreen.
  Future<bool> loginWithGoogle() async {
    isLoading = true; error = null; notifyListeners();
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        isLoading = false; notifyListeners();
        return false;
      }

      final name = googleUser.displayName ?? googleUser.email.split('@').first;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final uc = await FirebaseAuth.instance.signInWithCredential(credential);
      if (uc.user == null) throw Exception('Firebase sign-in failed');

      final firebaseToken = await uc.user!.getIdToken();
      if (firebaseToken == null) throw Exception('Firebase token unavailable');

      // Check if user exists first by using 'detect' role
      final data = await PocketBaseService.exchangeFirebaseToken(
        firebaseToken: firebaseToken,
        role: 'detect',
        displayName: name,
      );

      if (data['is_new'] == true) {
        _pendingFirebaseToken = firebaseToken;
        _pendingGoogleName = name;
        isLoading = false; notifyListeners();
        return false; // Show RolePickerScreen
      }

      // Existing user - log in immediately
      final record = data['record'];
      _user = AppUser(
        id: record['id'] ?? '',
        email: record['email'] ?? '',
        role: record['role'] ?? 'student',
        fullName: record['name'] ?? name,
        isActive: true,
        isVerified: true,
      );
      _pendingFirebaseToken = null;
      _pendingGoogleName = null;
      isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await PocketBaseService.logout();
    _user = null;
    notifyListeners();
  }
}
