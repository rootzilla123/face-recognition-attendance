import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _timer;

  void start() {
    _check();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  void stop() {
    _timer?.cancel();
    _controller.close();
  }

  Future<void> _check() async {
    final online = await HealthService.check();
    if (online != _isOnline) {
      _isOnline = online;
      _controller.add(_isOnline);
    }
  }

  // Cache helpers
  static Future<void> cacheJson(String key, String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', json);
  }

  static Future<String?> getCached(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cache_$key');
  }
}
