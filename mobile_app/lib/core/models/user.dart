class AppUser {
  final String id;
  final String email;
  final String role; // admin | teacher | student | parent
  final String fullName;
  final bool isActive;
  final bool isVerified;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.fullName,
    required this.isActive,
    required this.isVerified,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'].toString(),
        email: j['email'],
        role: j['role'],
        fullName: j['full_name'],
        isActive: j['is_active'] ?? true,
        isVerified: j['is_verified'] ?? false,
      );

  String get name => fullName;

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
  bool get isParent => role == 'parent';
}
