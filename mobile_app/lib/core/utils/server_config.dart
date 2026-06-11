import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const _apiKey = 'server_base_url';
  static const _pbKey = 'pocketbase_url';

  // No hardcoded defaults - user must configure on first launch
  static String? _current;
  static String? _pbCurrent;

  static String get baseUrl => _current ?? '';
  static String get pbUrl => _pbCurrent ?? '';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _current = prefs.getString(_apiKey);
    _pbCurrent = prefs.getString(_pbKey);
  }

  static Future<void> save(String url) async {
    _current = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKey, url);
  }

  static Future<void> setApiUrl(String url) async {
    _current = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKey, url);
  }

  static Future<String> getApiUrl() async {
    return _current ?? '';
  }

  static Future<void> savePbUrl(String url) async {
    _pbCurrent = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pbKey, url);
  }

  /// Predefined server options for easy switching
  static const Map<String, Map<String, String>> presetServers = {
    'localhost': {
      'label': 'Localhost',
      'api': 'http://127.0.0.1:8001',
      'pb': 'http://127.0.0.1:8092',
    },
    'local_network': {
      'label': 'Local Network (172.22.186.189)',
      'api': 'http://172.22.186.189:8001',
      'pb': 'http://172.22.186.189:8092',
    },
    'android_emulator': {
      'label': 'Android Emulator',
      'api': 'http://10.0.2.2:8001',
      'pb': 'http://10.0.2.2:8092',
    },
  };

  /// Set server by preset name
  static Future<void> setPreset(String presetName) async {
    final preset = presetServers[presetName];
    if (preset != null) {
      await save(preset['api']!);
      await savePbUrl(preset['pb']!);
    }
  }
}
