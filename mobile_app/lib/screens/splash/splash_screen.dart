import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shell.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../onboarding/server_setup_screen.dart';
import '../../core/services/health_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/common/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Initializing...';
  bool _backendOk = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _status = 'Optimizing connections...');
    _backendOk = await HealthService.check();
    if (mounted) setState(() => _status = _backendOk ? 'System Ready ✓' : 'Connecting to Cloud...');
    await AuthService.loadSession().catchError((_) {});
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    
    if (AuthService.isLoggedIn) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    } else {
      final prefs = await SharedPreferences.getInstance();
      final serverSetupDone = prefs.getBool('server_setup_done') ?? false;
      final onboardingDone = prefs.getBool('onboarding_done') ?? false;
      if (!mounted) return;
      
      if (!serverSetupDone) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => const ServerSetupScreen(),
        ));
      } else if (!onboardingDone) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.meshDark,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 100, showText: false)
              .animate()
              .scale(duration: 600.ms, curve: Curves.easeOutBack)
              .shimmer(delay: 800.ms, duration: 2.seconds),
            
            const SizedBox(height: 32),
            const Text('ShadomFacePro', 
              style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.2)
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            
            const Text('SMART ATTENDANCE REDEFINED', 
              style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            
            const SizedBox(height: 60),
            
            // Loading and Status
            SizedBox(
              width: 200,
              child: Column(
                children: [
                   ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(Colors.white38),
                      minHeight: 2,
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(_status, 
                      key: ValueKey(_status),
                      style: TextStyle(
                        color: _backendOk ? const Color(0xFF4ADE80) : Colors.white38, 
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      )
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
