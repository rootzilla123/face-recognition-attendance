import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _apiKey = 'server_base_url';
  static const _pbKey = 'pocketbase_url';

  // Production defaults — point to Cloudflare tunnel domains.
  // User can override in Settings screen for local dev.
  static const defaultUrl = 'https://api.YOUR_DOMAIN';
  static const defaultPbUrl = 'https://pb.YOUR_DOMAIN';

  static String _current = defaultUrl;
  static String _pbCurrent = defaultPbUrl;

  static String get baseUrl => _current;
  static String get pbUrl => _pbCurrent;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _current = prefs.getString(_apiKey) ?? defaultUrl;
    _pbCurrent = prefs.getString(_pbKey) ?? defaultPbUrl;
  }

  static Future<void> save(String url) async {
    _current = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKey, url);
  }

  static Future<void> savePbUrl(String url) async {
    _pbCurrent = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pbKey, url);
  }
}
