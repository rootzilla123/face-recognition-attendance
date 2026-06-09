import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _apiKey = 'server_base_url';
  static const _pbKey = 'pocketbase_url';

  // LOCAL DEVELOPMENT - configured by configure_local.sh
  static const defaultUrl = 'http://172.22.186.189:8001';
  static const defaultPbUrl = 'http://172.22.186.189:8092';

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
