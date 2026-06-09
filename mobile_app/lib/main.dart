import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/utils/server_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/pocketbase_service.dart';
import 'core/services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only on supported platforms (Android, iOS, Web)
  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }
  
  await ServerConfig.load();
  await PocketBaseService.loadSession();
  await NotificationService.init();
  ConnectivityService().start();
  runApp(const MyApp());
}
