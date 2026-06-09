import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/server_config.dart';
import '../api/endpoints.dart';

/// Handles all PocketBase auth operations
class PocketBaseService {
  static String get _pbUrl => ServerConfig.pbUrl;

  static const _tokenKey = 'pb_token';
  static const _userKey = 'pb_user';

  static String? _token;
  static Map<String, dynamic>? _user;

  static String? get token => _token;
  static Map<String, dynamic>? get user => _user;
  static bool get isLoggedIn => _token != null && _user != null;

  static String get userId => _user?['id'] ?? '';
  static String get userEmail => _user?['email'] ?? '';
  static String get userName => _user?['name'] ?? '';
  static String get userRole => _user?['role'] ?? 'student';
  static bool get isVerified => _user?['verified'] == true;

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try { _user = jsonDecode(userJson); } catch (_) {}
    }
    // Validate token is still good
    if (_token != null) {
      try {
        await refreshAuth();
      } on Exception catch (e) {
        // If it's a session-expired error, logout() was already called inside refreshAuth.
        // For network errors, keep the session so the user can still use cached data.
        if (e.toString().contains('Session expired')) rethrow;
      }
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_pbUrl/api/collections/users/auth-with-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identity': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['message'] ?? 'Login failed');
    }
    final data = jsonDecode(res.body);
    _token = data['token'];
    _user = data['record'];
    await _saveSession();
    return data['record'];
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    final res = await http.post(
      Uri.parse('$_pbUrl/api/collections/users/records'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
        'role': role,
        if (phone != null) 'phone': phone,
        'emailVisibility': true,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      final body = jsonDecode(res.body);
      final msg = _extractError(body);
      throw Exception(msg);
    }
    // Request email verification
    await requestVerification(email);
    return jsonDecode(res.body);
  }

  static Future<void> requestVerification(String email) async {
    await http.post(
      Uri.parse('$_pbUrl/api/collections/users/request-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
  }

  /// Returns { 'record': {...}, 'googleName': '...' }
  static Future<Map<String, dynamic>> signInWithGoogle({String defaultRole = 'student'}) async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleName = googleUser.displayName ?? googleUser.email.split('@').first;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) throw Exception('Firebase sign-in failed');

    final firebaseToken = await firebaseUser.getIdToken();

    final res = await http.post(
      Uri.parse('${Endpoints.apiV1}/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebase_token': firebaseToken, 'default_role': defaultRole}),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? body['message'] ?? 'Google sign-in failed');
    }

    final data = jsonDecode(res.body);
    _token = data['token'];
    _user = data['record'];
    await _saveSession();
    return {'record': data['record'], 'googleName': googleName};
  }

  static Future<Map<String, dynamic>> exchangeFirebaseToken({
    required String firebaseToken,
    required String role,
    required String displayName,
  }) async {
    final res = await http.post(
      Uri.parse('${Endpoints.apiV1}/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firebase_token': firebaseToken,
        'default_role': role,
        'display_name': displayName,
      }),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['detail'] ?? body['message'] ?? 'Google sign-in failed');
    }

    final data = jsonDecode(res.body);
    
    // session is only saved if we got a token (ie. not a 'detect' call for new user)
    if (data['token'] != null) {
      _token = data['token'];
      _user = data['record'];
      await _saveSession();
    }
    
    return data;
  }

  static Future<void> requestPasswordReset(String email) async {    final res = await http.post(
      Uri.parse('$_pbUrl/api/collections/users/request-password-reset'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Failed to send reset email');
    }
  }

  static Future<void> refreshAuth() async {
    if (_token == null) return;
    try {
      final res = await http.post(
        Uri.parse('$_pbUrl/api/collections/users/auth-refresh'),
        headers: {'Authorization': _token!},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        _user = data['record'];
        await _saveSession();
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        // Token is invalid — clear session so user is sent to login
        await logout();
        throw Exception('Session expired');
      }
      // Other errors (5xx, etc.) — keep existing session, don't force logout
    } on Exception {
      rethrow;
    }
  }

  static Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  static Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString(_tokenKey, _token!);
    if (_user != null) await prefs.setString(_userKey, jsonEncode(_user));
  }

  static String _extractError(Map<String, dynamic> body) {
    if (body['message'] != null) return body['message'];
    if (body['data'] != null) {
      final data = body['data'] as Map;
      for (final entry in data.entries) {
        final field = entry.value;
        if (field is Map && field['message'] != null) {
          return '${entry.key}: ${field['message']}';
        }
      }
    }
    return 'Registration failed';
  }

  /// Auth headers for FastAPI calls using PocketBase token
  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}
