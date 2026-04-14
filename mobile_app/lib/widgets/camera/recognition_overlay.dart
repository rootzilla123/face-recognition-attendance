import 'package:flutter/material.dart';
import 'dart:async';

class Detection {
  final double x, y, width, height;
  final String? studentName;
  final String? studentId;
  final double? confidence;

  const Detection({
    required this.x, required this.y,
    required this.width, required this.height,
    this.studentName, this.studentId, this.confidence,
  });

  factory Detection.fromJson(Map<String, dynamic> j) {
    // CompreFace returns box as {x_min, y_min, x_max, y_max}
    final box = j['box'] as Map<String, dynamic>?;
    double x = 0, y = 0, w = 0, h = 0;
    if (box != null) {
      x = (box['x_min'] as num?)?.toDouble() ?? (j['x'] as num?)?.toDouble() ?? 0;
      y = (box['y_min'] as num?)?.toDouble() ?? (j['y'] as num?)?.toDouble() ?? 0;
      final xMax = (box['x_max'] as num?)?.toDouble() ?? (x + ((j['width'] as num?)?.toDouble() ?? 0));
      final yMax = (box['y_max'] as num?)?.toDouble() ?? (y + ((j['height'] as num?)?.toDouble() ?? 0));
      w = xMax - x;
      h = yMax - y;
    } else {
      x = (j['x'] as num?)?.toDouble() ?? 0;
      y = (j['y'] as num?)?.toDouble() ?? 0;
      w = (j['width'] as num?)?.toDouble() ?? 0;
      h = (j['height'] as num?)?.toDouble() ?? 0;
    }

    final subjects = j['subjects'] as List?;
    String? name, id;
    double? conf;
    if (subjects != null && subjects.isNotEmpty) {
      final top = subjects.first as Map<String, dynamic>;
      name = top['subject']?.toString();
      id = name;
      conf = (top['similarity'] as num?)?.toDouble();
    }
    name ??= j['student_name']?.toString();
    id ??= j['student_id']?.toString();
    conf ??= (j['confidence'] as num?)?.toDouble();

    return Detection(x: x, y: y, width: w, height: h, studentName: name, studentId: id, confidence: conf);
  }
}

/// Draws face detection bounding boxes over a camera feed
/// Matches the web app's RecognitionOverlay component exactly
class RecognitionOverlay extends StatefulWidget {
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;
  final Duration autoHide;

  const RecognitionOverlay({
    super.key,
    required this.detections,
    this.imageWidth = 640,
    this.imageHeight = 480,
    this.autoHide = const Duration(seconds: 3),
  });

  @override
  State<RecognitionOverlay> createState() => _RecognitionOverlayState();
}

class _RecognitionOverlayState extends State<RecognitionOverlay> {
  List<Detection> _visible = [];
  Timer? _hideTimer;

  @override
  void didUpdateWidget(RecognitionOverlay old) {
    super.didUpdateWidget(old);
    if (widget.detections.isNotEmpty) {
      _hideTimer?.cancel();
      setState(() => _visible = widget.detections);
      _hideTimer = Timer(widget.autoHide, () {
        if (mounted) setState(() => _visible = []);
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_visible.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: CustomPaint(
        painter: _OverlayPainter(
          detections: _visible,
          imageWidth: widget.imageWidth,
          imageHeight: widget.imageHeight,
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;

  _OverlayPainter({required this.detections, required this.imageWidth, required this.imageHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    for (final d in detections) {
      final isRecognized = d.studentName != null && d.studentName!.isNotEmpty;
      final color = isRecognized ? const Color(0xFF22C55E) : const Color(0xFFEAB308);

      final rect = Rect.fromLTWH(
        d.x * scaleX, d.y * scaleY,
        d.width * scaleX, d.height * scaleY,
      );

      // Draw bounding box
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRect(rect, boxPaint);

      // Draw corner accents (like a targeting reticle)
      final cornerLen = rect.width * 0.15;
      final cornerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      _drawCorners(canvas, rect, cornerLen, cornerPaint);

      // Draw label background + text
      final label = isRecognized
          ? '${d.studentName}${d.confidence != null ? '  ${(d.confidence! * 100).toStringAsFixed(0)}%' : ''}'
          : 'Unknown';

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width + 40);

      final labelH = tp.height + 6;
      final labelRect = Rect.fromLTWH(rect.left, rect.top - labelH - 2, tp.width + 12, labelH);

      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(4)),
        Paint()..color = color.withValues(alpha: 0.9),
      );

      tp.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 3));
    }
  }

  void _drawCorners(Canvas canvas, Rect rect, double len, Paint paint) {
    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, len), paint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, len), paint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -len), paint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.detections != detections;
}
