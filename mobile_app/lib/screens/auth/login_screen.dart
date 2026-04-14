import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../core/utils/server_config.dart';
import '../shell.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _googleLoading = false;

  Future<void> _login() async {
    final ok = await context.read<AuthProvider>().login(_email.text.trim(), _pass.text);
    if (ok && mounted) {
      context.read<WebSocketProvider>().connect();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    }
  }

  Future<void> _showServerConfig() async {
    final ctrl = TextEditingController(text: ServerConfig.baseUrl);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Server URL', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'http://192.168.x.x:8090',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final url = ctrl.text.trim();
              if (url.isNotEmpty) {
                // Save both FastAPI (8001) and PocketBase (8090) URLs derived from input
                final apiUrl = url.replaceAll(':8090', ':8001').replaceAll(':8000', ':8001');
                final pbUrl = url.replaceAll(':8001', ':8090').replaceAll(':8000', ':8090');
                await ServerConfig.save(apiUrl);
                await ServerConfig.savePbUrl(pbUrl);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    final ok = await context.read<AuthProvider>().loginWithGoogle();
    setState(() => _googleLoading = false);
    if (ok && mounted) {
      context.read<WebSocketProvider>().connect();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF030712), Color(0xFF0F172A), Color(0xFF0C1445)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary500, AppColors.secondary600]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Text('📸', style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(height: 16),
                const Text('AttendanceAI', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Welcome back', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showServerConfig,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.dns_outlined, color: Colors.white38, size: 13),
                      const SizedBox(width: 5),
                      Text(ServerConfig.pbUrl, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(width: 5),
                      const Icon(Icons.edit_outlined, color: Colors.white38, size: 11),
                    ]),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(children: [
                    if (auth.error != null)
                      GestureDetector(
                        onTap: auth.error!.toLowerCase().contains('socket') ||
                               auth.error!.toLowerCase().contains('connection') ||
                               auth.error!.toLowerCase().contains('network') ||
                               auth.error!.toLowerCase().contains('refused')
                            ? _showServerConfig : null,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.error500.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.error500.withValues(alpha: 0.3))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(auth.error!, style: const TextStyle(color: AppColors.error500, fontSize: 13)),
                            if (auth.error!.toLowerCase().contains('socket') ||
                                auth.error!.toLowerCase().contains('connection') ||
                                auth.error!.toLowerCase().contains('network') ||
                                auth.error!.toLowerCase().contains('refused'))
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text('Tap here to update the server URL', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12)),
                              ),
                          ]),
                        ),
                      ),
                    if (auth.isLoggedIn && !auth.isVerified)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.warning50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.warning500)),
                        child: const Row(children: [
                          Icon(Icons.warning_amber_outlined, color: AppColors.warning500, size: 18),
                          SizedBox(width: 8),
                          Expanded(child: Text('Please verify your email. Check your inbox for a verification link.', style: TextStyle(color: AppColors.orange700, fontSize: 12))),
                        ]),
                      ),

                    // Google Sign-In button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: (_googleLoading || auth.isLoading) ? null : _googleSignIn,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _googleLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Image.network('https://www.google.com/favicon.ico', width: 18, height: 18,
                                  errorBuilder: (_, __, ___) => const Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                const SizedBox(width: 10),
                                const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(children: [
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                    ]),
                    const SizedBox(height: 16),

                    _field(_email, 'Email', Icons.email_outlined, TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _passField(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: auth.isLoading ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13), textAlign: TextAlign.center),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text("Don't have an account? ", style: TextStyle(color: Colors.white54, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Register', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: ctrl, keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary500)),
      ),
    );
  }

  Widget _passField() {
    return TextField(
      controller: _pass, obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password', labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38, size: 20),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20), onPressed: () => setState(() => _obscure = !_obscure)),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary500)),
      ),
    );
  }
}

