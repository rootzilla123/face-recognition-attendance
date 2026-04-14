import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../providers/student_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/app_theme.dart';
import '../../core/api/endpoints.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/common/error_state.dart';
import 'student_detail_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<StudentProvider>().fetchStudents());
  }

  void _confirmDelete(String studentId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text('Are you sure you want to delete $name? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<StudentProvider>().deleteStudent(studentId);
              if (mounted) showSnack(context, ok ? 'Student deleted' : context.read<StudentProvider>().error ?? 'Failed', error: !ok);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StudentProvider>();
    final filtered = prov.students.where((s) =>
        s.fullName.toLowerCase().contains(_search.toLowerCase()) ||
        s.studentId.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<StudentProvider>().fetchStudents(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GradientHeader(
                title: 'Students',
                subtitle: 'Manage student profiles and face recognition data',
                action: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4F46E5)),
                  onPressed: () => _showAddForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                ),
              ),
            ),
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: InputDecoration(
                    hintText: 'Search by name or ID...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gray200)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: prov.isLoading && prov.students.isEmpty
                  ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                  : prov.error != null && prov.students.isEmpty
                      ? SliverToBoxAdapter(child: ErrorState(message: prov.error!, onRetry: () => context.read<StudentProvider>().fetchStudents()))
                      : filtered.isEmpty
                          ? SliverToBoxAdapter(child: EmptyState(
                              emoji: '👥',
                              title: _search.isEmpty ? 'No students yet' : 'No results found',
                              subtitle: _search.isEmpty ? 'Add your first student to get started' : 'Try a different search term',
                              action: _search.isEmpty ? FilledButton.icon(onPressed: () => _showAddForm(context), icon: const Icon(Icons.add), label: const Text('Add Student')) : null,
                            ))
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _StudentTile(student: filtered[i], onDelete: () => _confirmDelete(filtered[i].studentId, filtered[i].fullName)),
                                childCount: filtered.length,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddStudentSheet(),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final dynamic student;
  final VoidCallback onDelete;
  const _StudentTile({required this.student, required this.onDelete});

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: student.fullName);
    final gradeCtrl = TextEditingController(text: student.gradeLevel);
    final sectionCtrl = TextEditingController(text: student.section ?? '');
    final phoneCtrl = TextEditingController(text: student.parentPhone);
    final emailCtrl = TextEditingController(text: student.parentEmail);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit ${student.fullName}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _editField(nameCtrl, 'Full Name'),
            _editField(gradeCtrl, 'Grade Level'),
            _editField(sectionCtrl, 'Section'),
            _editField(phoneCtrl, 'Parent Phone'),
            _editField(emailCtrl, 'Parent Email'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context.read<StudentProvider>().updateStudent(student.studentId, {
                'full_name': nameCtrl.text.trim(),
                'grade_level': gradeCtrl.text.trim(),
                'section': sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
                'parent_phone': phoneCtrl.text.trim(),
                'parent_email': emailCtrl.text.trim(),
              });
              if (context.mounted) showSnack(context, ok ? 'Student updated' : 'Failed', error: !ok);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: ctrl, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
  );

  @override
  Widget build(BuildContext context) {
    final initials = student.fullName.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final photoUrl = Endpoints.studentPhoto(student.studentId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(student: student))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            width: 44, height: 44,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(22)),
              child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.blueGradient),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
            ),
          ),
        ),
        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.gray900)),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            Text(student.studentId, style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primary100, borderRadius: BorderRadius.circular(999)),
              child: Text(student.gradeLevel, style: const TextStyle(fontSize: 11, color: AppColors.primary700, fontWeight: FontWeight.w500)),
            ),
            if (student.section != null)
              Text('• ${student.section}', style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
          ],
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary600, size: 20),
            onPressed: () => _showEditDialog(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error500, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
    );
  }
}

class _AddStudentSheet extends StatefulWidget {
  const _AddStudentSheet();

  @override
  State<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<_AddStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _studentId = TextEditingController();
  final _fullName = TextEditingController();
  final _gradeLevel = TextEditingController();
  final _section = TextEditingController();
  final _parentPhone = TextEditingController();
  final _parentEmail = TextEditingController();
  File? _photo;
  bool _uploading = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null) {
      showSnack(context, 'Please select a student photo', error: true);
      return;
    }
    setState(() => _uploading = true);
    final file = await http.MultipartFile.fromPath('photo', _photo!.path);
    if (!mounted) return;
    final prov = context.read<StudentProvider>();
    final ok = await prov.createStudent(
          studentId: _studentId.text.trim(),
          fullName: _fullName.text.trim(),
          gradeLevel: _gradeLevel.text.trim(),
          section: _section.text.trim().isEmpty ? null : _section.text.trim(),
          parentPhone: _parentPhone.text.trim(),
          parentEmail: _parentEmail.text.trim(),
          photo: file,
        );
    setState(() => _uploading = false);
    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        showSnack(context, 'Student created successfully');
      } else {
        showSnack(context, context.read<StudentProvider>().error ?? 'Failed', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Student', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              // Photo picker
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: _photo != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_photo!, fit: BoxFit.cover))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.camera_alt, size: 36, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to upload student photo', style: TextStyle(color: Colors.grey)),
                          Text('Required for face recognition', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ]),
                ),
              ),
              const SizedBox(height: 12),
              _field(_studentId, 'Student ID', required: true),
              _field(_fullName, 'Full Name', required: true),
              _field(_gradeLevel, 'Grade Level', required: true),
              _field(_section, 'Section'),
              _field(_parentPhone, 'Parent Phone', required: true, keyboard: TextInputType.phone),
              _field(_parentEmail, 'Parent Email', required: true, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _uploading ? null : _submit,
                    child: _uploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Student'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _uploading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool required = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      ),
    );
  }
}
