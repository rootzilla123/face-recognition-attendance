import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/attendance.dart';
import '../utils/helpers.dart';

class ExportService {
  Future<String> exportAndShareCsv(List<AttendanceRecord> records, String start, String end) async {
    final path = await _writeCsv(records, start, end);
    await Share.shareXFiles([XFile(path)], subject: 'Attendance Report $start to $end');
    return path;
  }

  Future<String> exportAndShareTxt(List<AttendanceRecord> records, String start, String end) async {
    final path = await _writeTxt(records, start, end);
    await Share.shareXFiles([XFile(path)], subject: 'Attendance Report $start to $end');
    return path;
  }

  Future<String> _writeCsv(List<AttendanceRecord> records, String start, String end) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/attendance_${start}_to_$end.csv');
    final buf = StringBuffer();
    buf.writeln('Student ID,Location,Date,Time,Confidence');
    for (final r in records) {
      buf.writeln('"${r.studentId}","${r.cameraLocation}","${formatDate(r.timestamp)}","${formatTime(r.timestamp)}","${formatPercent(r.confidenceScore)}"');
    }
    await file.writeAsString(buf.toString());
    return file.path;
  }

  Future<String> _writeTxt(List<AttendanceRecord> records, String start, String end) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/attendance_${start}_to_$end.txt');
    final buf = StringBuffer();
    buf.writeln('ATTENDANCE REPORT');
    buf.writeln('Period: $start to $end');
    buf.writeln('Generated: ${formatDateTime(DateTime.now())}');
    buf.writeln('Total Records: ${records.length}');
    buf.writeln('=' * 50);
    buf.writeln();
    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      buf.writeln('${i + 1}. Student #${r.studentId}');
      buf.writeln('   Location: ${r.cameraLocation}');
      buf.writeln('   Time: ${formatDateTime(r.timestamp)}');
      buf.writeln('   Confidence: ${formatPercent(r.confidenceScore)}');
      buf.writeln();
    }
    await file.writeAsString(buf.toString());
    return file.path;
  }
}
