import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/attendance.dart';
import '../models/mark.dart';
import '../models/student.dart';
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

  Future<String> exportAndSharePdf(List<AttendanceRecord> records, String start, String end, {Map<String, String>? studentNames}) async {
    final path = await _writePdf(records, start, end, studentNames: studentNames);
    await Share.shareXFiles([XFile(path)], subject: 'Attendance Report $start to $end');
    return path;
  }

  Future<String> exportAndShareMarksPdf(List<Mark> marks, Student student) async {
    final path = await _writeMarksPdf(marks, student);
    await Share.shareXFiles([XFile(path)], subject: 'Report Card - ${student.fullName}');
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

  Future<String> _writePdf(List<AttendanceRecord> records, String start, String end, {Map<String, String>? studentNames}) async {
    final doc = pw.Document();

    // Per-location breakdown
    final byLocation = <String, int>{};
    for (final r in records) {
      byLocation[r.cameraLocation] = (byLocation[r.cameraLocation] ?? 0) + 1;
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('Attendance Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
        pw.Text('Period: $start to $end'),
        pw.Text('Generated: ${formatDateTime(DateTime.now())}'),
        pw.Text('Total Records: ${records.length}'),
        pw.SizedBox(height: 12),

        // Per-location summary
        pw.Text('By Location', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headers: ['Location', 'Check-ins'],
          data: byLocation.entries.map((e) => [e.key, e.value.toString()]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
        ),
        pw.SizedBox(height: 16),

        // Full records
        pw.Text('All Records', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headers: ['#', 'Student', 'Location', 'Date', 'Time', 'Conf.'],
          data: records.asMap().entries.map((e) {
            final r = e.value;
            final name = studentNames?[r.studentId] ?? r.studentId;
            return [
              '${e.key + 1}',
              name,
              r.cameraLocation,
              formatDate(r.timestamp),
              formatTime(r.timestamp),
              formatPercent(r.confidenceScore),
            ];
          }).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 8),
        ),
      ],
    ));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/attendance_${start}_to_$end.pdf');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  Future<String> _writeMarksPdf(List<Mark> marks, Student student) async {
    final doc = pw.Document();
    
    // Try to load logo
    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logo != null) pw.Image(logo, width: 60, height: 60),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('SHADOMFACE PRO ACADEMY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.Text('Knowledge for the Future', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                  pw.Text('Email: support@shadomfacepro.com | Web: shadomfacepro.org', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 2, color: PdfColors.blue900),
          pw.SizedBox(height: 10),
          
          pw.Center(child: pw.Text('STUDENT PROGRESS REPORT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2))),
          pw.SizedBox(height: 20),

          // Student Info
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _pdfInfoRow('Student Name:', student.fullName),
                    _pdfInfoRow('Student ID:', student.studentId),
                  ],
                )),
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _pdfInfoRow('Grade Level:', student.gradeLevel),
                    _pdfInfoRow('Section:', student.section ?? 'N/A'),
                  ],
                )),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Marks Table
          pw.Text('Academic Performance', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Subject', 'Term', 'Score', 'Max', '%', 'Grade', 'Remarks'],
            data: marks.map((m) => [
              m.subject,
              m.term,
              m.score.toStringAsFixed(1),
              m.maxScore.toStringAsFixed(0),
              '${m.percentage.toStringAsFixed(1)}%',
              m.grade ?? 'N/A',
              m.remarks ?? '',
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              6: const pw.FlexColumnWidth(4),
            },
          ),
          pw.SizedBox(height: 40),

          // Summary & Footer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Report Date: ${formatDate(DateTime.now())}'),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide()))),
                  pw.Text('Class Teacher Signature', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.SizedBox(height: 30),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 150, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide()))),
                  pw.Text('Principal Signature', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.Spacer(),
          pw.Center(child: pw.Text('This is a computer-generated report and does not require a physical stamp.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600))),
        ],
      ),
    ));

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Report_${student.studentId}.pdf');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(text: pw.TextSpan(children: [
        pw.TextSpan(text: '$label ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
      ])),
    );
  }
}
