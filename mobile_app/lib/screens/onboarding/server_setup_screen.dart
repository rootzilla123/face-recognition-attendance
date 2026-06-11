import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/server_config.dart';
import '../../core/services/health_service.dart';
import '../../core/utils/app_theme.dart';
import '../auth/login_screen.dart';

class ServerSetupScreen extends StatefulWidget {
  const ServerSetupScreen({super.key});
  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  final _urlController = TextEditingController();
  final _pbUrlController = TextEditingController();
  bool _isLoading = false;
  bool _testPassed = false;
  String _testMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final apiUrl = await ServerConfig.getApiUrl();
    final pbUrl = await ServerConfig.getPbUrl();
    if (mounted) {
      _urlController.text = apiUrl;
      _pbUrlController.text = pbUrl;
    }
  }

  Future<void> _testConnection() async {
    if (_urlController.text.isEmpty) {
      setState(() {
        _testMessage = 'Please enter API server URL';
        _testPassed = false;
      });
      return;
    }

    if (_pbUrlController.text.isEmpty) {
      setState(() {
        _testMessage = 'Please enter PocketBase URL';
        _testPassed = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _testMessage = 'Testing connection...';
      _testPassed = false;
    });

    try {
      // Temporarily set the URLs for testing
      await ServerConfig.setApiUrl(_urlController.text);
      await ServerConfig.setPbUrl(_pbUrlController.text);
      final isHealthy = await HealthService.check();

      if (mounted) {
        setState(() {
          _testPassed = isHealthy;
          _testMessage = isHealthy
              ? '✓ Connection successful'
              : '✗ Server not responding';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testPassed = false;
          _testMessage = '✗ Connection failed: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (_testPassed) {
      await ServerConfig.setApiUrl(_urlController.text);
      await ServerConfig.setPbUrl(_pbUrlController.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('server_setup_done', true);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please test connection first')),
      );
    }
  }

  void _usePreset(String url) {
    _urlController.text = url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.meshDark,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Server Configuration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideX(begin: -0.2),
                const SizedBox(height: 8),
                const Text(
                  'Configure your server connection to get started',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                const SizedBox(height: 40),

                // Quick Presets
                const Text(
                  'Quick Presets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetButton('localhost', 'http://localhost:8001'),
                    _presetButton('Local Network', 'http://192.168.1.100:8001'),
                    _presetButton('Android Emulator', 'http://10.0.2.2:8001'),
                  ],
                ),
                const SizedBox(height: 32),

                // Custom URL Input
                const Text(
                  'API Server URL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'http://192.168.1.1:8001',
                    hintStyle: TextStyle(color: Colors.white30),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary500),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),

                // PocketBase URL Input
                const Text(
                  'PocketBase URL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pbUrlController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'http://192.168.1.1:8092',
                    hintStyle: TextStyle(color: Colors.white30),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary500),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),

                // Test Connection Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testConnection,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary500,
                      disabledBackgroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Test Connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Message
                if (_testMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _testPassed
                          ? Colors.green.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _testPassed
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _testPassed ? Icons.check_circle : Icons.error_outline,
                          color: _testPassed ? Colors.green[400] : Colors.red[300],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _testMessage,
                            style: TextStyle(
                              color: _testPassed
                                  ? const Color(0xFF4ADE80)
                                  : Colors.red[300],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scaleY(begin: 0.8),
                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _testPassed ? _saveAndContinue : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green[700],
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _presetButton(String label, String url) {
    return OutlinedButton(
      onPressed: () => _usePreset(url),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
