class Student {
  final String id;
  final String studentId;
  final String fullName;
  final String gradeLevel;
  final String? section;
  final String? parentName;
  final String parentPhone;
  final String parentEmail;
  final bool isActive;

  const Student({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.gradeLevel,
    this.section,
    this.parentName,
    required this.parentPhone,
    required this.parentEmail,
    required this.isActive,
  });

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id']?.toString() ?? '',
        studentId: j['student_id']?.toString() ?? '',
        fullName: j['full_name']?.toString() ?? j['name']?.toString() ?? 'Unknown',
        gradeLevel: j['grade_level']?.toString() ?? '',
        section: j['section']?.toString(),
        parentName: j['parent_name']?.toString(),
        parentPhone: j['parent_phone']?.toString() ?? '',
        parentEmail: j['parent_email']?.toString() ?? '',
        isActive: j['is_active'] ?? true,
      );
}
