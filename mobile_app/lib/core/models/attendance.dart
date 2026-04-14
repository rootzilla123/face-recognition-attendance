class AttendanceRecord {
  final String id;
  final String studentId;
  final String cameraLocation;
  final DateTime timestamp;
  final double confidenceScore;
  final String? faceImageUrl;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.cameraLocation,
    required this.timestamp,
    required this.confidenceScore,
    this.faceImageUrl,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'].toString(),
        studentId: j['student_id'].toString(),
        cameraLocation: j['camera_location'],
        timestamp: DateTime.parse(j['timestamp']),
        confidenceScore: (j['confidence_score'] as num).toDouble(),
        faceImageUrl: j['face_image_url'],
      );
}

class AttendanceStats {
  final int totalStudents;
  final int presentStudents;
  final int absentStudents;
  final double attendancePercentage;

  const AttendanceStats({
    required this.totalStudents,
    required this.presentStudents,
    required this.absentStudents,
    required this.attendancePercentage,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> j) => AttendanceStats(
        totalStudents: j['total_students'],
        presentStudents: j['present_students'],
        absentStudents: j['absent_students'],
        attendancePercentage: (j['attendance_percentage'] as num).toDouble(),
      );
}
