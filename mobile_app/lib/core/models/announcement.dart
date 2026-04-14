class Announcement {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final List<String> targetRoles;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.authorName,
    required this.targetRoles,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'].toString(),
        title: j['title'] ?? '',
        content: j['content'] ?? '',
        authorName: j['author_name'] ?? j['author']?['full_name'] ?? 'System',
        targetRoles: (j['target_roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
