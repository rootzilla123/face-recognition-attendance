import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../core/services/pocketbase_service.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import '../shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _role = 'student';
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _studentId = TextEditingController();
  final _grade = TextEditingController();
  final _section = TextEditingController();
  final _phone = TextEditingController();
  File? _photo;
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _done = false;

  Future<void> _pickPhoto() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (p != null) setState(() => _photo = File(p.path));
  }

  Future<void> _submit() async {
    if (_email.text.isEmpty || _pass.text.isEmpty || _name.text.isEmpty) {
      setState(() => _error = 'Please fill all required fields');
      return;
    }
    if (_role == 'student' && (_studentId.text.isEmpty || _grade.text.isEmpty)) {
      setState(() => _error = 'Student ID and Grade are required');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // Step 1: Create user in PocketBase
      await PocketBaseService.register(
        email: _email.text.trim(),
        password: _pass.text,
        name: _name.text.trim(),
        role: _role,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );

      // Step 2: If student, also register in FastAPI with face photo
      if (_role == 'student') {
        try {
          final client = ApiClient();
          final fields = {
            'email': _email.text.trim(),
            'password': _pass.text,
            'full_name': _name.text.trim(),
            'student_id': _studentId.text.trim(),
            'grade_level': _grade.text.trim(),
            if (_section.text.isNotEmpty) 'section': _section.text.trim(),
            if (_phone.text.isNotEmpty) 'parent_phone': _phone.text.trim(),
            'parent_email': _email.text.trim(),
          };
          if (_photo != null) {
            final file = await http.MultipartFile.fromPath('photo', _photo!.path);
            await client.postMultipart('/auth/register/student', fields.map((k, v) => MapEntry(k, v)), file: file);
          } else {
            await client.post('/auth/register/student', fields);
          }
        } catch (_) {
          // FastAPI registration is best-effort — PocketBase account already created
        }
      } else if (_role == 'parent') {
        try {
          await ApiClient().post('/auth/register/parent', {
            'email': _email.text.trim(),
            'password': _pass.text,
            'full_name': _name.text.trim(),
            if (_phone.text.isNotEmpty) 'phone': _phone.text.trim(),
          });
        } catch (_) {}
      }

      setState(() { _done = true; _loading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF030712), Color(0xFF0F172A), Color(0xFF0C1445)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _done ? _successView() : _formView(),
        ),
      ),
    );
  }

  Widget _successView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.success500.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(40)),
            child: const Center(child: Text('📧', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 20),
          const Text('Account Created!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'We\'ve sent a verification link to your email address.\n\nPlease check your inbox and click the link to verify your account before signing in.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary600, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Go to Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _formView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),
        // Google sign-up button
        _GoogleSignUpButton(),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or register with email', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12))),
          Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
        ]),
        const SizedBox(height: 16),
        // Role selector
        Container(          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: Row(children: ['student', 'parent'].map((r) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _role = r),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: _role == r ? AppColors.primary600 : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                child: Text(r[0].toUpperCase() + r.substring(1), textAlign: TextAlign.center, style: TextStyle(color: _role == r ? Colors.white : Colors.white54, fontWeight: FontWeight.w600)),
              ),
            ),
          )).toList()),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: Column(children: [
            if (_error != null) Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.error500.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(color: AppColors.error500, fontSize: 12)),
            ),
            _field(_email, 'Email *', TextInputType.emailAddress),
            const SizedBox(height: 10),
            _passField(),
            const SizedBox(height: 10),
            _field(_name, 'Full Name *', TextInputType.name),
            if (_role == 'student') ...[
              const SizedBox(height: 10),
              _field(_studentId, 'Student ID *', TextInputType.text),
              const SizedBox(height: 10),
              _field(_grade, 'Grade Level *', TextInputType.text),
              const SizedBox(height: 10),
              _field(_section, 'Section', TextInputType.text),
              const SizedBox(height: 10),
              _field(_phone, 'Parent Phone', TextInputType.phone),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                  child: _photo != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_photo!, fit: BoxFit.cover, width: double.infinity))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.camera_alt, color: Colors.white38),
                          SizedBox(height: 4),
                          Text('Upload face photo (optional)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ]),
                ),
              ),
            ],
            if (_role == 'parent') ...[
              const SizedBox(height: 10),
              _field(_phone, 'Phone', TextInputType.phone),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary600, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label, TextInputType type) => TextField(
    controller: ctrl, keyboardType: type,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary500)),
    ),
  );

  Widget _passField() => TextField(
    controller: _pass, obscureText: _obscure,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: 'Password *', labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18), onPressed: () => setState(() => _obscure = !_obscure)),
      filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary500)),
    ),
  );
}

class _GoogleSignUpButton extends StatefulWidget {
  @override
  State<_GoogleSignUpButton> createState() => _GoogleSignUpButtonState();
}

class _GoogleSignUpButtonState extends State<_GoogleSignUpButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().loginWithGoogle();
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.read<WebSocketProvider>().connect();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } else {
      final err = context.read<AuthProvider>().error ?? 'Google sign-in failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _loading ? null : _signIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('G', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4285F4))),
                SizedBox(width: 10),
                Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
              ]),
      ),
    );
  }
}
