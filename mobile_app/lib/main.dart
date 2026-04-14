import 'package:flutter/material.dart';
import 'app.dart';
import 'core/utils/server_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/pocketbase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServerConfig.load();
  await PocketBaseService.loadSession();
  await NotificationService.init();
  runApp(const MyApp());
}
