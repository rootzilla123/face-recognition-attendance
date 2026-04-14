import 'package:flutter/material.dart';
import '../shell.dart';
import '../auth/login_screen.dart';
import '../../core/services/health_service.dart';
import '../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Starting up...';
  bool _backendOk = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _status = 'Checking server...');
    _backendOk = await HealthService.check();
    if (mounted) setState(() => _status = _backendOk ? 'Connected ✓' : 'Server offline');
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (AuthService.isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF9333EA)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(child: Text('📸', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 20),
          const Text('AttendanceAI', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Face Recognition System', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 40),
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(_status, key: ValueKey(_status),
              style: TextStyle(color: _backendOk ? const Color(0xFF4ADE80) : Colors.white54, fontSize: 13)),
          ),
        ])),
      ),
    );
  }
}
