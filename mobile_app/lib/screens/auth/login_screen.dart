import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../core/utils/app_theme.dart';
import '../../widgets/common/app_logo.dart';
import '../shell.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'role_picker_screen.dart';

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

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithGoogle();
    setState(() => _googleLoading = false);
    if (!mounted) return;
    if (ok) {
      context.read<WebSocketProvider>().connect();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppShell()));
    } else if (auth.pendingGoogleName != null) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => RolePickerScreen(googleName: auth.pendingGoogleName!),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const AppLogo(size: 72, showText: false),
              const SizedBox(height: 16),
              const Text(
                'AttendanceAI',
                style: TextStyle(
                  color: AppColors.gray900,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(color: AppColors.gray500, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  children: [
                    if (auth.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error100),
                        ),
                        child: Text(
                          auth.error!,
                          style: const TextStyle(color: AppColors.error700, fontSize: 14),
                        ),
                      ),
                    _field(_email, 'Email Address', Icons.alternate_email_rounded, TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _passField(),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: auth.isLoading ? null : _login,
                        child: auth.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: (_googleLoading || auth.isLoading) ? null : _googleSignIn,
                        child: _googleLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Continue with Google'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? ", style: TextStyle(color: AppColors.gray500, fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Sign Up', style: TextStyle(color: AppColors.primary600, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, TextInputType type) {
    return TextField(
      controller: ctrl, keyboardType: type,
      style: const TextStyle(color: AppColors.gray900, fontSize: 15),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppColors.gray500),
        prefixIcon: Icon(icon, color: AppColors.gray400, size: 22),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary500, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _passField() {
    return TextField(
      controller: _pass, obscureText: _obscure,
      style: const TextStyle(color: AppColors.gray900, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Password', labelStyle: const TextStyle(color: AppColors.gray500),
        prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.gray400, size: 22),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.gray400, size: 22),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary500, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}
