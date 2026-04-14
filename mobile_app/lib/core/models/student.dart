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
        id: j['id'].toString(),
        studentId: j['student_id'],
        fullName: j['full_name'],
        gradeLevel: j['grade_level'],
        section: j['section'],
        parentName: j['parent_name'],
        parentPhone: j['parent_phone'],
        parentEmail: j['parent_email'],
        isActive: j['is_active'] ?? true,
      );
}
