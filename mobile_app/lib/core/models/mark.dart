class Mark {
  final String id;
  final String studentId;
  final String studentName;
  final String subject;
  final String term;
  final double score;
  final double maxScore;
  final double percentage;
  final String? grade;
  final String? remarks;
  final bool isPublished;
  final DateTime createdAt;

  Mark({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subject,
    required this.term,
    required this.score,
    required this.maxScore,
    required this.percentage,
    this.grade,
    this.remarks,
    required this.isPublished,
    required this.createdAt,
  });

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(
      id: json['id'],
      studentId: json['student_id'],
      studentName: json['student_name'],
      subject: json['subject'],
      term: json['term'],
      score: (json['score'] as num).toDouble(),
      maxScore: (json['max_score'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      grade: json['grade'],
      remarks: json['remarks'],
      isPublished: json['is_published'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'subject': subject,
      'term': term,
      'score': score,
      'max_score': maxScore,
      'percentage': percentage,
      'grade': grade,
      'remarks': remarks,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
