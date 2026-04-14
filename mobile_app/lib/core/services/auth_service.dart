// AuthService now delegates to PocketBaseService
// Kept as a thin wrapper so existing code doesn't break
import 'pocketbase_service.dart';
import '../models/user.dart';

class AuthService {
  static bool get isLoggedIn => PocketBaseService.isLoggedIn;
  static String? get token => PocketBaseService.token;
  static AppUser? get currentUser {
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

  static Map<String, String> get authHeaders => PocketBaseService.authHeaders;

  static Future<void> loadSession() => PocketBaseService.loadSession();
  static Future<void> logout() => PocketBaseService.logout();

  static Future<AppUser> login(String email, String password) async {
    final record = await PocketBaseService.login(email, password);
    return AppUser(
      id: record['id'] ?? '',
      email: record['email'] ?? '',
      role: record['role'] ?? 'student',
      fullName: record['name'] ?? '',
      isActive: true,
      isVerified: record['verified'] == true,
    );
  }
}
