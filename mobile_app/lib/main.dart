import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'core/utils/server_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/pocketbase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServerConfig.load();
  await PocketBaseService.loadSession();
  await NotificationService.init();

  await SentryFlutter.init(
    (options) => options
      ..dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: 'https://ac3cf00c929b47dab37d4e23d69ff569@app.glitchtip.com/22231',
      )
      ..tracesSampleRate = 0.01
      ..enableAutoSessionTracking = false,
    appRunner: () => runApp(const MyApp()),
  );
}
